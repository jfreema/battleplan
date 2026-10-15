import 'dart:async';
import 'dart:convert';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/imports/application/providers.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/imports/presentation/import_parts.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The largest calendar file the import takes (the callable's limit).
const _maxFileBytes = 1000000;

/// Importing a team's events from a calendar link (SPEC IMPORT-7,
/// IMPORT-8): GameChanger's or TeamReach's, or a calendar file saved from
/// either. Only events: those apps' chat and files aren't available.
/// Preview what's new, then import. RSVPs and attendance stay behind.
class CalendarImportForm extends ConsumerStatefulWidget {
  const new({
    required this.groupId,
    required this.source,
    required this.onBusy,
    required this.onDone,
    super.key,
  });

  final GroupId groupId;
  final ImportSource source;
  final ValueChanged<bool> onBusy;
  final ValueChanged<ImportReport> onDone;

  @override
  ConsumerState<CalendarImportForm> createState() => _CalendarImportState();
}

class _CalendarImportState extends ConsumerState<CalendarImportForm> {
  final _link = TextEditingController();

  /// A calendar file chosen instead of the link: its name and text.
  ({String name, String text})? _file;
  bool _events = true;
  bool _includePast = false;
  bool _busy = false;
  String? _error;
  EventImportResult? _preview;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  /// Any change means the preview is out of date.
  void _changed() => setState(() {
    _preview = null;
    _error = null;
  });

  void _setBusy(bool busy) {
    setState(() => _busy = busy);
    widget.onBusy(busy);
  }

  Future<void> _chooseFile() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref
        .read(fileChooserProvider)
        .pickFile(extensions: const ['ics']);
    if (picked == null || !mounted) return;
    if (picked.size > _maxFileBytes) {
      setState(() => _error = l10n.importFileTooLarge);
      return;
    }
    final text = utf8.decode(await picked.readBytes(), allowMalformed: true);
    if (!mounted) return;
    setState(() {
      _file = (name: picked.name, text: text);
      _preview = null;
      _error = null;
    });
  }

  Future<void> _run({required bool dryRun}) async {
    final l10n = AppLocalizations.of(context);
    final link = _link.text.trim();
    if (_file == null && link.isEmpty) {
      setState(() => _error = l10n.importNeedLink);
      return;
    }
    setState(() => _error = null);
    _setBusy(true);
    try {
      final result = await ref
          .read(importRepositoryProvider)
          .importEvents(
            widget.groupId,
            source: widget.source,
            includePast: _includePast,
            dryRun: dryRun,
            url: _file == null ? link : null,
            ics: _file?.text,
          );
      if (!mounted) return;
      if (dryRun) {
        setState(() => _preview = result);
      } else {
        widget.onDone(
          ImportReport(
            lines: [l10n.importDone(result.added)],
            actions: [
              (
                label: l10n.importOpenSchedule,
                route: '/g/${widget.groupId.value}/schedule',
              ),
            ],
          ),
        );
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = importFailureText(l10n, e, widget.source));
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final source = widget.source;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final preview = _preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.importWhat, style: theme.textTheme.titleSmall),
        // Each kind on its own; these apps have only events (IMPORT-2).
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _events,
          onChanged: _busy
              ? null
              : (v) {
                  _events = v ?? false;
                  _changed();
                },
          title: Text(l10n.importEvents),
          subtitle: Text(l10n.importEventsHelp),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: false,
          onChanged: null,
          title: Text(l10n.importMessages),
          subtitle: Text(switch (source) {
            ImportSource.teamreach => l10n.importMessagesUnavailableTeamReach,
            _ => l10n.importMessagesUnavailableGameChanger,
          }),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: false,
          onChanged: null,
          title: Text(l10n.importDocuments),
          subtitle: Text(switch (source) {
            ImportSource.teamreach => l10n.importDocumentsUnavailableTeamReach,
            _ => l10n.importDocumentsUnavailableGameChanger,
          }),
        ),
        Text(l10n.importNoRsvps, style: muted),
        const SizedBox(height: Space.lg),
        Text(
          l10n.importLinkTitle(source.label),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: Space.sm),
        Text(switch (source) {
          ImportSource.teamreach => l10n.importTeamReachSteps,
          _ => l10n.importGameChangerSteps,
        }),
        const SizedBox(height: Space.md),
        if (_file case final file?)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.schedule),
            title: Text(file.name),
            trailing: IconButton(
              tooltip: l10n.importRemoveFile,
              icon: const Icon(AppIcons.close),
              onPressed: _busy
                  ? null
                  : () {
                      _file = null;
                      _changed();
                    },
            ),
          )
        else ...[
          TextField(
            controller: _link,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              labelText: l10n.importLinkLabel,
              hintText: 'webcal://…',
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _busy ? null : () => unawaited(_chooseFile()),
              child: Text(l10n.importUseFile),
            ),
          ),
        ],
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _includePast,
          onChanged: _busy
              ? null
              : (v) {
                  _includePast = v ?? false;
                  _changed();
                },
          title: Text(l10n.importIncludePast),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: Space.sm),
          Text(error, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: Space.lg),
        if (preview == null)
          FilledButton(
            onPressed: _busy || !_events
                ? null
                : () => unawaited(_run(dryRun: true)),
            child: _busy ? const ButtonSpinner() : Text(l10n.importPreview),
          )
        else ...[
          EventPreview(result: preview, source: source),
          const SizedBox(height: Space.lg),
          if (preview.added > 0)
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_run(dryRun: false)),
              child: _busy
                  ? const ButtonSpinner()
                  : Text(l10n.importRun(preview.added)),
            ),
        ],
      ],
    );
  }
}
