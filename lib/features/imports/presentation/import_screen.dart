import 'dart:async';
import 'dart:convert';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/imports/application/providers.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/schedule/schedule.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The largest calendar file the import takes (the callable's limit).
const _maxFileBytes = 1000000;

/// Import at `/g/:groupId/import` (SPEC §6.15): the team's admins bring
/// events over from another app. GameChanger first, from its schedule's
/// calendar link or a calendar file: choose what to import (events; chat
/// and documents aren't available from GameChanger), preview what's new,
/// then import. RSVPs and attendance stay behind. Importing again adds
/// only what's new.
class ImportScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _link = TextEditingController();

  /// A calendar file chosen instead of the link: its name and text.
  ({String name, String text})? _file;
  bool _events = true;
  bool _includePast = false;
  bool _busy = false;
  String? _error;
  EventImportResult? _preview;
  EventImportResult? _done;

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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(importRepositoryProvider)
          .importEvents(
            widget.groupId,
            source: ImportSource.gamechanger,
            includePast: _includePast,
            dryRun: dryRun,
            url: _file == null ? link : null,
            ics: _file?.text,
          );
      if (!mounted) return;
      setState(() => dryRun ? _preview = result : _done = result);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = _failure(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _failure(AppLocalizations l10n, AppFailure e) => switch (e) {
    InvalidInput(message: 'bad-link') => l10n.importBadLink,
    InvalidInput(message: 'calendar-unreachable') => l10n.importUnreachable,
    InvalidInput(message: 'not-a-calendar') => l10n.importNotCalendar,
    InvalidInput(message: 'calendar-too-large') => l10n.importTooLarge,
    InvalidInput(message: 'too-many-events') => l10n.importTooMany,
    StorageFull() => l10n.importStorageFull,
    PermissionDenied(message: 'team-archived') => l10n.teamArchived,
    PermissionDenied() => l10n.notAllowed,
    RateLimited() => l10n.signInRateLimited,
    Offline() => l10n.signInOffline,
    _ => l10n.importFailed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final admin =
        (ref.watch(myMembershipProvider(widget.groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final Widget body;
    if (!admin) {
      body = EmptyState(icon: AppIcons.block, message: l10n.notAllowed);
    } else if (_done case final done?) {
      body = _Done(groupId: widget.groupId, result: done);
    } else {
      final muted = theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
      final preview = _preview;
      body = ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          Text(l10n.importIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.lg),
          Text(l10n.importFrom, style: theme.textTheme.titleSmall),
          // The one source so far, chosen (IMPORT-1).
          RadioGroup<ImportSource>(
            groupValue: ImportSource.gamechanger,
            onChanged: (_) {},
            child: RadioListTile<ImportSource>(
              contentPadding: EdgeInsets.zero,
              value: ImportSource.gamechanger,
              title: Text(l10n.importGameChanger),
              subtitle: Text(l10n.importGameChangerHelp),
            ),
          ),
          Text(l10n.importComingSoon, style: muted),
          const SizedBox(height: Space.lg),
          Text(l10n.importWhat, style: theme.textTheme.titleSmall),
          // Each kind on its own; GameChanger has only events (IMPORT-2).
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
            subtitle: Text(l10n.importMessagesUnavailable),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: false,
            onChanged: null,
            title: Text(l10n.importDocuments),
            subtitle: Text(l10n.importDocumentsUnavailable),
          ),
          Text(l10n.importNoRsvps, style: muted),
          const SizedBox(height: Space.lg),
          Text(l10n.importLinkTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.sm),
          Text(l10n.importLinkSteps),
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
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.importPreview),
            )
          else ...[
            _Preview(result: preview),
            const SizedBox(height: Space.lg),
            if (preview.added > 0)
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_run(dryRun: false)),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.importRun(preview.added)),
              ),
          ],
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: body,
        ),
      ),
    );
  }
}

/// When an event starts, in its own zone, as the schedule shows it.
String _when(BuildContext context, ImportedEventSample e) {
  final locale = Localizations.localeOf(context).toString();
  if (e.allDay && e.startDate != null) {
    return DateFormat.MMMEd(locale).format(DateTime.parse(e.startDate!));
  }
  final wall = ZonedTime.isKnown(e.timeZone)
      ? ZonedTime.wallClock(e.timeZone, e.start)
      : e.start.toLocal();
  return DateFormat.MMMEd(locale).add_jm().format(wall);
}

/// What importing would add, with what it leaves and why (IMPORT-3).
class _Preview extends StatelessWidget {
  const new({required this.result});

  final EventImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = MaterialLocalizations.of(context);
    final r = result;
    final lines = [
      if (r.alreadyImported > 0) l10n.importAlready(r.alreadyImported),
      if (r.past > 0) l10n.importPast(r.past),
      if (r.skippedCount > 0) l10n.importSkipped(r.skippedCount),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          r.added == 0 ? l10n.importNothingNew : l10n.importToAdd(r.added),
          style: theme.textTheme.titleMedium,
        ),
        if (r.first case final first?)
          Text(
            r.last == null || r.last == first
                ? dates.formatMediumDate(first.toLocal())
                : '${dates.formatMediumDate(first.toLocal())} – '
                      '${dates.formatMediumDate(r.last!.toLocal())}',
          ),
        if (lines.isNotEmpty) Text(lines.join(' · ')),
        const SizedBox(height: Space.sm),
        for (final e in r.sample)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(typeIcon(e.type), color: typeColor(context, e.type)),
            title: Text(e.title),
            subtitle: Text(
              [_when(context, e), if (e.place.isNotEmpty) e.place].join(' · '),
            ),
          ),
        if (r.added > r.sample.length)
          Text(l10n.importAndMore(r.added - r.sample.length)),
        if (r.skipped.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(l10n.importSkippedTitle, style: theme.textTheme.titleSmall),
          for (final s in r.skipped)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.title.isEmpty ? l10n.importUntitled : s.title),
              subtitle: Text(switch (s.reason) {
                ImportSkipReason.canceled => l10n.importSkipCanceled,
                ImportSkipReason.repeat => l10n.importSkipRepeat,
                ImportSkipReason.unreadable => l10n.importSkipUnreadable,
              }),
            ),
        ],
      ],
    );
  }
}

/// The report once it's done (IMPORT-5), and the way to the schedule.
class _Done extends StatelessWidget {
  const new({required this.groupId, required this.result});

  final GroupId groupId;
  final EventImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        const Icon(AppIcons.going, size: 48),
        const SizedBox(height: Space.md),
        Text(
          l10n.importDone(result.added),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Space.xl),
        FilledButton(
          onPressed: () => context.go('/g/${groupId.value}/schedule'),
          child: Text(l10n.importOpenSchedule),
        ),
      ],
    );
  }
}
