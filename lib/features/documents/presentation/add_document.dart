import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/photo_location.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_repository.dart';
import 'package:battleplan/features/documents/presentation/document_actions.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The + menu (DOC-2, DOC-3): Upload file, which full storage turns off
/// with the STORE-4 message, and Add link, which uses no storage.
Future<void> showAddDocument(
  BuildContext context,
  WidgetRef ref,
  Group group,
) async {
  final l10n = AppLocalizations.of(context);
  final full = group.storageFull;
  final choice = await showAdaptiveSheet<String>(
    context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.upload),
              title: Text(l10n.documentsUploadFile),
              // Greyed when full; a tap still says why (STORE-4).
              textColor: full ? Theme.of(sheet).disabledColor : null,
              iconColor: full ? Theme.of(sheet).disabledColor : null,
              onTap: () => Navigator.of(sheet).pop('file'),
            ),
            ListTile(
              leading: const Icon(AppIcons.link),
              title: Text(l10n.documentsAddLink),
              onTap: () => Navigator.of(sheet).pop('link'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'file':
      if (full) {
        showStorageFull(context);
      } else {
        await uploadDocument(context, ref, group.id);
      }
    case 'link':
      await addLink(context, ref, group.id);
  }
}

/// Picks a file, checks its type and size, then opens the upload form
/// (DOC-2).
Future<void> uploadDocument(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
) async {
  final l10n = AppLocalizations.of(context);
  final picked = await ref
      .read(fileChooserProvider)
      .pickFile(extensions: documentContentTypes.keys.toList());
  if (picked == null || !context.mounted) return;
  final contentType = contentTypeForFile(picked.name);
  if (contentType == null) {
    showAppSnackBar(context, l10n.documentTypeNotAllowed);
    return;
  }
  // The limit is the platform setting (ADMIN-7).
  if (!fitsUploadLimit(context, ref, picked.size)) return;
  final done = await showAdaptiveSheet<bool>(
    context,
    builder: (_) => UploadForm(
      groupId: groupId,
      fileName: picked.name,
      size: picked.size,
      contentType: contentType,
      readBytes: picked.readBytes,
    ),
  );
  if ((done ?? false) && context.mounted) {
    showAppSnackBar(context, l10n.documentUploaded);
  }
}

/// Rename before uploading, an optional description, Notify team, then
/// progress with Cancel (DOC-2, DOC-6).
class UploadForm extends ConsumerStatefulWidget {
  const new({
    required this.groupId,
    required this.fileName,
    required this.size,
    required this.contentType,
    required this.readBytes,
    super.key,
  });

  final GroupId groupId;
  final String fileName;
  final int size;
  final String contentType;
  final Future<Uint8List> Function() readBytes;

  @override
  ConsumerState<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends ConsumerState<UploadForm> {
  late final _name = TextEditingController(text: widget.fileName);
  final _description = TextEditingController();
  bool _notify = true;
  DocumentUpload? _upload;
  StreamSubscription<double>? _progressSub;
  double _progress = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    unawaited(_progressSub?.cancel());
    // Closing the sheet mid-upload cancels it, like Cancel.
    if (_busy) unawaited(_upload?.cancel());
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(documentRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      // A JPEG's location comes out first, as with photos (Privacy Policy).
      final bytes = stripPhotoLocation(await widget.readBytes());
      if (!mounted) return;
      final id = repo.newDocumentId();
      final upload = repo.uploadFile(
        widget.groupId,
        id,
        fileName: widget.fileName,
        bytes: bytes,
        contentType: widget.contentType,
      );
      _upload = upload;
      _progressSub = upload.progress.listen((p) {
        if (mounted) setState(() => _progress = p);
      }, onError: (Object _) {});
      final path = await upload.done;
      await repo.createFile(
        widget.groupId,
        id,
        UserId(uid),
        name: _name.text.trim(),
        description: _description.text.trim(),
        path: path,
        contentType: widget.contentType,
        size: bytes.length,
        notifyTeam: _notify,
      );
      _busy = false;
      if (mounted) Navigator.of(context).pop(true);
    } on UploadCanceled {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.documentUploadCanceled;
        });
      }
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = switch (e) {
            // Storage filled up after the + menu opened; the rules refuse
            // it, and STORE-4 has one message for that.
            PermissionDenied() when _storageFull() => l10n.storageFullMessage,
            PermissionDenied() => l10n.documentUploadRefused,
            _ => l10n.documentUploadFailed,
          };
        });
      }
    } finally {
      unawaited(_progressSub?.cancel());
      _progressSub = null;
    }
  }

  /// The team's storage is full now (STORE-4).
  bool _storageFull() =>
      ref.read(groupProvider(widget.groupId)).value?.storageFull ?? false;

  Future<void> _cancel() async {
    await _upload?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
            Text(l10n.documentUploadTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(
                  documentIcon(documentTypeOf(widget.contentType)),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    '${widget.fileName} · ${formatBytes(widget.size)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            DocumentFields(
              name: _name,
              description: _description,
              enabled: !_busy,
              onChanged: () => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.documentNotifyTeam),
              subtitle: Text(l10n.documentNotifyTeamHelp),
              value: _notify,
              onChanged: _busy ? null : (v) => setState(() => _notify = v),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_busy) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: Space.sm),
              Text(l10n.documentUploading((_progress * 100).round())),
              const SizedBox(height: Space.sm),
              OutlinedButton(
                onPressed: () => unawaited(_cancel()),
                child: Text(l10n.cancel),
              ),
            ] else
              FilledButton(
                onPressed: valid ? () => unawaited(_start()) : null,
                child: Text(l10n.documentUploadButton),
              ),
          ],
        ),
      ),
    );
  }
}

/// A name and a web address (DOC-3). Works when storage is full.
Future<void> addLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
) async {
  final l10n = AppLocalizations.of(context);
  final added = await showAdaptiveSheet<bool>(
    context,
    builder: (_) => LinkForm(groupId: groupId),
  );
  if ((added ?? false) && context.mounted) {
    showAppSnackBar(context, l10n.documentLinkAdded);
  }
}

class LinkForm extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends ConsumerState<LinkForm> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _description = TextEditingController();
  bool _notify = true;
  bool _saving = false;
  bool _showUrlError = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final url = parseDocumentUrl(_url.text);
    final uid = ref.read(authUserProvider).value?.uid;
    if (url == null) {
      setState(() => _showUrlError = true);
      return;
    }
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(documentRepositoryProvider)
          .createLink(
            widget.groupId,
            UserId(uid),
            name: _name.text.trim(),
            url: url,
            description: _description.text.trim(),
            notifyTeam: _notify,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.documentActionFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final valid =
        isValidDocumentName(_name.text) &&
        _url.text.trim().isNotEmpty &&
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
            Text(l10n.documentLinkTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            Text(l10n.documentLinkHelp),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _url,
              enabled: !_saving,
              keyboardType: TextInputType.url,
              autocorrect: false,
              maxLength: Limits.documentUrlMax,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
              decoration: InputDecoration(
                labelText: l10n.documentUrlLabel,
                hintText: 'https://',
                errorText: _showUrlError ? l10n.documentUrlInvalid : null,
              ),
              onChanged: (_) => setState(() => _showUrlError = false),
            ),
            const SizedBox(height: Space.sm),
            DocumentFields(
              name: _name,
              description: _description,
              enabled: !_saving,
              onChanged: () => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.documentNotifyTeam),
              subtitle: Text(l10n.documentNotifyTeamHelp),
              value: _notify,
              onChanged: _saving ? null : (v) => setState(() => _notify = v),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: valid && !_saving ? () => unawaited(_save()) : null,
              child: Text(l10n.documentAddLinkButton),
            ),
          ],
        ),
      ),
    );
  }
}
