import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/button_spinner.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart' show formatBytes;
import 'package:battleplan/features/imports/application/groupme_import.dart';
import 'package:battleplan/features/imports/application/providers.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/imports/domain/groupme_export.dart';
import 'package:battleplan/features/imports/presentation/import_parts.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The largest export a browser can be asked to open.
const int _maxExportBytes = 2000 * 1024 * 1024;

/// Importing a GroupMe group (SPEC IMPORT-9) from its data export: the
/// messages, with their photos, into the chat; files shared in the group
/// into Documents; and its calendar's events into the schedule. Each is
/// chosen on its own. The export is read on this device; preview what's in
/// it, then import with progress, and stop at any time.
class GroupMeImportForm extends ConsumerStatefulWidget {
  const new({
    required this.groupId,
    required this.onBusy,
    required this.onDone,
    super.key,
  });

  final GroupId groupId;
  final ValueChanged<bool> onBusy;
  final ValueChanged<ImportReport> onDone;

  @override
  ConsumerState<GroupMeImportForm> createState() => _GroupMeImportState();
}

class _GroupMeImportState extends ConsumerState<GroupMeImportForm> {
  String? _fileName;
  GroupMeExport? _export;
  String? _groupMeId;
  bool _messages = true;
  bool _photos = true;
  bool _documents = true;
  bool _events = true;
  bool _includePast = false;
  bool _reading = false;
  bool _busy = false;
  bool _previewed = false;
  EventImportResult? _eventsPreview;
  GroupMeImporter? _importer;
  GroupMeProgress? _progress;
  String? _error;

  GroupMeGroup? get _group {
    final groups = _export?.groups ?? const <GroupMeGroup>[];
    for (final g in groups) {
      if (g.id == _groupMeId) return g;
    }
    return null;
  }

  /// Any change means the preview is out of date.
  void _changed() => setState(() {
    _previewed = false;
    _eventsPreview = null;
    _error = null;
  });

  void _setBusy(bool busy) {
    setState(() => _busy = busy);
    widget.onBusy(busy);
  }

  Future<void> _choose() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref
        .read(fileChooserProvider)
        .pickFile(extensions: const ['zip']);
    if (picked == null || !mounted) return;
    if (picked.size > _maxExportBytes) {
      setState(() => _error = l10n.importExportTooLarge);
      return;
    }
    setState(() {
      _reading = true;
      _error = null;
    });
    widget.onBusy(true);
    try {
      final bytes = await picked.readBytes();
      // Let the spinner show before the export is read.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final export = readGroupMeExport(bytes);
      if (!mounted) return;
      setState(() {
        _fileName = picked.name;
        _export = export;
        _groupMeId = export.groups.length == 1 ? export.groups.single.id : null;
        _previewed = false;
        _eventsPreview = null;
      });
    } on NotGroupMeExport catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.reason == 'no-groups'
            ? l10n.importNoGroups
            : l10n.importNotExport,
      );
    } on Object {
      // Out of memory, or a file the browser couldn't read.
      if (!mounted) return;
      setState(() => _error = l10n.importNotExport);
    } finally {
      if (mounted) setState(() => _reading = false);
      widget.onBusy(false);
    }
  }

  Future<void> _preview() async {
    final group = _group;
    if (group == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    _setBusy(true);
    try {
      // The events are checked by the server, as for a calendar import:
      // what's new, past, or canceled.
      final events = _events && group.events.isNotEmpty
          ? await ref
                .read(importRepositoryProvider)
                .importEvents(
                  widget.groupId,
                  source: ImportSource.groupme,
                  includePast: _includePast,
                  dryRun: true,
                  events: group.events,
                )
          : null;
      if (!mounted) return;
      setState(() {
        _eventsPreview = events;
        _previewed = true;
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = importFailureText(l10n, e, ImportSource.groupme));
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _import() async {
    final group = _group;
    final export = _export;
    if (group == null || export == null) return;
    final l10n = AppLocalizations.of(context);
    final importer = GroupMeImporter(
      ref.read(importRepositoryProvider),
      widget.groupId,
      export,
    );
    setState(() {
      _importer = importer;
      _error = null;
    });
    _setBusy(true);
    try {
      final totals = await importer.run(
        group,
        messages: _messages,
        photos: _photos,
        documents: _documents,
        events: _events,
        includePast: _includePast,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      widget.onDone(_report(l10n, totals));
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = importFailureText(l10n, e, ImportSource.groupme));
    } finally {
      if (mounted) {
        setState(() {
          _importer = null;
          _progress = null;
        });
        _setBusy(false);
      }
    }
  }

  ImportReport _report(AppLocalizations l10n, GroupMeTotals t) {
    final g = widget.groupId.value;
    final already = t.messagesAlready + t.documentsAlready;
    final leftOut = t.photosLeftOut + t.documentsLeftOut;
    final nothing =
        t.messagesAdded + t.documentsAdded + t.eventsAdded == 0 && !t.canceled;
    return ImportReport(
      lines: [
        if (nothing)
          l10n.importNothingNew
        else if (_messages)
          l10n.importMessagesDone(t.messagesAdded),
        if (_documents && t.documentsAdded > 0)
          l10n.importDocumentsDone(t.documentsAdded),
        if (_events && t.eventsAdded > 0) l10n.importDone(t.eventsAdded),
        if (already > 0) l10n.importAlreadyThere(already),
        if (t.storageFull)
          l10n.importStorageFilled
        else if (leftOut > 0)
          l10n.importCouldNotAdd(leftOut),
        if (t.canceled) l10n.importStopped,
      ],
      actions: [
        if (_messages) (label: l10n.importOpenChat, route: '/g/$g/chat'),
        if (_documents && t.documentsAdded > 0)
          (label: l10n.importOpenDocuments, route: '/g/$g/documents'),
        if (_events && t.eventsAdded > 0)
          (label: l10n.importOpenSchedule, route: '/g/$g/schedule'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final export = _export;
    final group = _group;
    final working = _busy || _reading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.importGroupMeTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: Space.sm),
        Text(l10n.importGroupMeSteps),
        const SizedBox(height: Space.md),
        if (export == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: working ? null : () => unawaited(_choose()),
              icon: _reading
                  ? const ButtonSpinner()
                  : const Icon(AppIcons.download),
              label: Text(
                _reading ? l10n.importReadingExport : l10n.importChooseExport,
              ),
            ),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.chat),
            title: Text(_fileName ?? ''),
            trailing: IconButton(
              tooltip: l10n.importRemoveFile,
              icon: const Icon(AppIcons.close),
              onPressed: working
                  ? null
                  : () => setState(() {
                      _export = null;
                      _fileName = null;
                      _groupMeId = null;
                      _previewed = false;
                      _eventsPreview = null;
                      _error = null;
                    }),
            ),
          ),
        if (export != null && export.groups.length > 1) ...[
          const SizedBox(height: Space.md),
          Text(l10n.importWhichGroup, style: theme.textTheme.titleSmall),
          RadioGroup<String>(
            groupValue: _groupMeId,
            onChanged: (id) {
              if (working) return;
              _groupMeId = id;
              _changed();
            },
            child: Column(
              children: [
                for (final g in export.groups)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: g.id,
                    enabled: !working,
                    title: Text(g.name),
                    subtitle: Text(l10n.importMessageCount(g.messages.length)),
                  ),
              ],
            ),
          ),
        ],
        if (group != null) ..._choices(context, group, working, muted),
        if (_error case final error?) ...[
          const SizedBox(height: Space.sm),
          Text(error, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (group != null) ...[
          const SizedBox(height: Space.lg),
          if (_progress case final p?)
            _Progress(progress: p, onStop: _importer?.cancel)
          else if (!_previewed)
            FilledButton(
              onPressed: working || !_anything(group)
                  ? null
                  : () => unawaited(_preview()),
              child: _busy ? const ButtonSpinner() : Text(l10n.importPreview),
            )
          else ...[
            _GroupMePreview(
              group: group,
              messages: _messages,
              photos: _photos,
              documents: _documents,
              events: _events ? _eventsPreview : null,
              freeBytes: _freeBytes(),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: working ? null : () => unawaited(_import()),
              child: _busy ? const ButtonSpinner() : Text(l10n.importStart),
            ),
          ],
        ],
      ],
    );
  }

  /// Whether anything chosen has something to bring.
  bool _anything(GroupMeGroup g) =>
      (_messages && g.messages.isNotEmpty) ||
      (_documents && g.files.isNotEmpty) ||
      (_events && g.events.isNotEmpty);

  /// The team's free storage, or null before the team is read.
  int? _freeBytes() {
    final team = ref.watch(groupProvider(widget.groupId)).value;
    if (team == null || team.storageQuotaBytes <= 0) return null;
    return math.max(0, team.storageQuotaBytes - team.storageBytes);
  }

  List<Widget> _choices(
    BuildContext context,
    GroupMeGroup group,
    bool working,
    TextStyle? muted,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = MaterialLocalizations.of(context);
    final first = group.first;
    final last = group.last;
    CheckboxListTile box({
      required bool value,
      required bool available,
      required ValueChanged<bool> onChanged,
      required String title,
      required String subtitle,
      bool indent = false,
    }) => CheckboxListTile(
      contentPadding: EdgeInsetsDirectional.only(start: indent ? Space.xl : 0),
      controlAffinity: ListTileControlAffinity.leading,
      value: available && value,
      onChanged: working || !available
          ? null
          : (v) {
              onChanged(v ?? false);
              _changed();
            },
      title: Text(title),
      subtitle: Text(subtitle),
    );
    return [
      const SizedBox(height: Space.lg),
      Text(l10n.importWhat, style: theme.textTheme.titleSmall),
      // Each kind on its own (IMPORT-2).
      box(
        value: _messages,
        available: group.messages.isNotEmpty,
        onChanged: (v) => _messages = v,
        title: l10n.importMessages,
        subtitle: first == null || last == null
            ? l10n.importNoMessages
            : '${l10n.importMessageCount(group.messages.length)} · '
                  '${dates.formatMediumDate(first.toLocal())} – '
                  '${dates.formatMediumDate(last.toLocal())}',
      ),
      if (group.messages.isNotEmpty)
        box(
          value: _photos && _messages,
          available: _messages && group.photoCount > 0,
          onChanged: (v) => _photos = v,
          title: l10n.importIncludePhotos,
          subtitle: group.photoCount == 0
              ? l10n.importNoPhotos
              : l10n.importPhotoCount(
                  group.photoCount,
                  formatBytes(group.photoBytes),
                ),
          indent: true,
        ),
      box(
        value: _documents,
        available: group.files.isNotEmpty,
        onChanged: (v) => _documents = v,
        title: l10n.importDocuments,
        subtitle: group.files.isEmpty
            ? l10n.importNoFiles
            : l10n.importFileCount(group.files.length),
      ),
      box(
        value: _events,
        available: group.events.isNotEmpty,
        onChanged: (v) => _events = v,
        title: l10n.importEvents,
        subtitle: group.events.isEmpty
            ? l10n.importNoEventDetails
            : l10n.importEventCount(group.events.length),
      ),
      if (group.events.isNotEmpty)
        box(
          value: _includePast && _events,
          available: _events,
          onChanged: (v) => _includePast = v,
          title: l10n.importIncludePast,
          subtitle: l10n.importIncludePastHelp,
          indent: true,
        ),
      Text(l10n.importGroupMeNotImported, style: muted),
    ];
  }
}

/// How the import is going, and the way to stop it.
class _Progress extends StatelessWidget {
  const new({required this.progress, required this.onStop});

  final GroupMeProgress progress;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(switch (p.step) {
          GroupMeStep.events => l10n.importAddingEvents,
          GroupMeStep.documents => l10n.importAddingDocuments(p.done, p.total),
          GroupMeStep.messages => l10n.importAddingMessages(p.done, p.total),
        }),
        const SizedBox(height: Space.sm),
        LinearProgressIndicator(value: p.total == 0 ? null : p.done / p.total),
        const SizedBox(height: Space.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: onStop, child: Text(l10n.importStop)),
        ),
      ],
    );
  }
}

/// What importing the group would bring, and what it leaves (IMPORT-3).
class _GroupMePreview extends StatelessWidget {
  const new({
    required this.group,
    required this.messages,
    required this.photos,
    required this.documents,
    required this.events,
    required this.freeBytes,
  });

  final GroupMeGroup group;
  final bool messages;
  final bool photos;
  final bool documents;
  final EventImportResult? events;
  final int? freeBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final left = group.leftOut;
    final bytes =
        (messages && photos ? group.photoBytes : 0) +
        (documents ? group.fileBytes : 0);
    final free = freeBytes;
    final recent = messages
        ? group.messages.reversed.take(3).toList().reversed
        : const <GroupMeMessage>[];
    final leftLines = [
      if (left.systemMessages > 0) l10n.importLeftSystem(left.systemMessages),
      if (left.videos > 0) l10n.importLeftVideos(left.videos),
      if (left.polls > 0) l10n.importLeftPolls(left.polls),
      if (left.photosNotInExport > 0)
        l10n.importLeftPhotosMissing(left.photosNotInExport),
      if (left.filesNotInExport > 0)
        l10n.importLeftFilesMissing(left.filesNotInExport),
      if (left.filesUnsupported > 0)
        l10n.importLeftFilesUnsupported(left.filesUnsupported),
      if (left.filesTooLarge > 0)
        l10n.importLeftFilesTooLarge(left.filesTooLarge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (messages) ...[
          Text(
            l10n.importMessagesToAdd(group.messages.length),
            style: theme.textTheme.titleMedium,
          ),
          for (final m in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(m.authorName),
              subtitle: Text(
                m.text.trim().isEmpty
                    ? l10n.importPhotos(m.photos.length)
                    : m.text.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        if (documents && group.files.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(
            l10n.importDocumentsToAdd(group.files.length),
            style: theme.textTheme.titleMedium,
          ),
          for (final f in group.files.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(AppIcons.document),
              title: Text(f.name),
              subtitle: Text(formatBytes(f.size)),
            ),
          if (group.files.length > 5)
            Text(l10n.importAndMore(group.files.length - 5)),
        ],
        if (bytes > 0) ...[
          const SizedBox(height: Space.md),
          Text(
            free != null && bytes > free
                ? l10n.importNoRoom(formatBytes(bytes), formatBytes(free))
                : free != null
                ? l10n.importRoom(formatBytes(bytes), formatBytes(free))
                : l10n.importRoomUnknown(formatBytes(bytes)),
            style: free != null && bytes > free
                ? TextStyle(color: theme.colorScheme.error)
                : null,
          ),
        ],
        if (events case final e?) ...[
          const SizedBox(height: Space.md),
          EventPreview(result: e, source: ImportSource.groupme),
        ],
        if (leftLines.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(l10n.importLeftOutTitle, style: theme.textTheme.titleSmall),
          for (final line in leftLines) Text('· $line'),
        ],
        const SizedBox(height: Space.sm),
        Text(l10n.importSkipsRepeats, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
