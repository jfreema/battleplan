import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/file_chooser.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/button_spinner.dart';
import 'package:battleplan/features/documents/domain/document_rules.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart' show formatBytes;
import 'package:battleplan/features/imports/application/providers.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/imports/domain/roster_file.dart';
import 'package:battleplan/features/imports/presentation/import_parts.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The largest roster file read (a team's roster is a few kilobytes).
const int _maxRosterBytes = 2 * 1024 * 1024;

/// Players per add (functions Limits.pastedRosterLinesMax).
const int _playersPerAdd = 200;

/// A file chosen to become a document, and its ID.
typedef _File = ({PickedFile file, String sourceId, String contentType});

/// Importing a team from TeamSnap (SPEC IMPORT-11), each kind on its own:
/// the schedule from its calendar link, the players from a roster export,
/// and documents from files downloaded from TeamSnap. TeamSnap doesn't
/// export its chat. Preview all of it, then import.
class TeamSnapImportForm extends ConsumerStatefulWidget {
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
  ConsumerState<TeamSnapImportForm> createState() => _TeamSnapImportState();
}

class _TeamSnapImportState extends ConsumerState<TeamSnapImportForm> {
  static const ImportSource _source = ImportSource.teamsnap;

  bool _events = true;
  bool _documents = true;

  /// Players, unless unticked; a basic group has none (TEAM-14).
  bool _playersChosen = true;
  bool get _players =>
      _playersChosen &&
      (ref.read(groupProvider(widget.groupId)).value?.hasPlayers ?? true);
  set _players(bool v) => _playersChosen = v;

  final _link = TextEditingController();
  CalendarFile? _ics;
  bool _includePast = false;

  String? _rosterName;
  RosterFile? _roster;

  List<_File> _files = const [];
  int _filesUnsupported = 0;
  int _filesTooLarge = 0;

  bool _busy = false;
  bool _previewed = false;
  EventImportResult? _eventsPreview;
  List<RosterRow> _newPlayers = const [];
  int _playersOnRoster = 0;
  List<_File> _newFiles = const [];
  int _filesImported = 0;
  String? _progress;
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
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

  bool get _hasEvents => _ics != null || _link.text.trim().isNotEmpty;

  /// Something chosen has something to bring.
  bool get _ready =>
      (_events && _hasEvents) ||
      (_players && (_roster?.players.isNotEmpty ?? false)) ||
      (_documents && _files.isNotEmpty);

  Future<void> _chooseCalendar() async {
    final l10n = AppLocalizations.of(context);
    final file = await pickCalendarFile(
      ref.read(fileChooserProvider),
      l10n,
      onError: (e) => setState(() => _error = e),
    );
    if (file == null || !mounted) return;
    _ics = file;
    _changed();
  }

  Future<void> _chooseRoster() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref
        .read(fileChooserProvider)
        .pickFile(extensions: const ['csv']);
    if (picked == null || !mounted) return;
    if (picked.size > _maxRosterBytes) {
      setState(() => _error = l10n.importNotRoster);
      return;
    }
    final text = rosterText(await picked.readBytes());
    if (!mounted) return;
    try {
      final roster = readRosterCsv(text);
      _rosterName = picked.name;
      _roster = roster;
      _changed();
    } on NotRosterFile {
      setState(() => _error = l10n.importNotRoster);
    }
  }

  Future<void> _chooseFiles() async {
    final picked = await ref
        .read(fileChooserProvider)
        .pickFiles(extensions: documentExtensions);
    if (picked.isEmpty || !mounted) return;
    final files = <_File>[];
    var unsupported = 0;
    var tooLarge = 0;
    for (final f in picked) {
      final type = documentTypeOf(f.name);
      if (type == null) {
        unsupported++;
      } else if (f.size > maxDocumentBytes) {
        tooLarge++;
      } else {
        files.add((
          file: f,
          sourceId: fileSourceId(f.name, f.size),
          contentType: type,
        ));
      }
    }
    _files = files;
    _filesUnsupported = unsupported;
    _filesTooLarge = tooLarge;
    _changed();
  }

  ChatImportDocument _document(_File f, String sharedBy) {
    final id = importedItemId(
      widget.groupId,
      _source,
      ImportItemKind.document,
      f.sourceId,
    );
    return ChatImportDocument(
      sourceId: f.sourceId,
      name: f.file.name,
      path:
          'groups/${widget.groupId.value}/documents/$id/'
          '${storageFileName(f.file.name)}',
      sharedByName: sharedBy,
      sharedAt: DateTime.now(),
    );
  }

  String get _myName =>
      ref.read(myMembershipProvider(widget.groupId))?.displayName ?? '';

  Future<void> _preview() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    _setBusy(true);
    try {
      final repo = ref.read(importRepositoryProvider);
      final events = _events && _hasEvents
          ? await repo.importEvents(
              widget.groupId,
              source: _source,
              includePast: _includePast,
              dryRun: true,
              url: _ics == null ? _link.text.trim() : null,
              ics: _ics?.text,
            )
          : null;
      // Players already on the roster, by name, stay as they are.
      var fresh = const <RosterRow>[];
      var onRoster = 0;
      if (_players && _roster != null) {
        final players = ref.read(playerRepositoryProvider);
        final active = await players.watchPlayers(widget.groupId).first;
        final pending = await players.watchPendingPlayers(widget.groupId).first;
        final names = {
          for (final p in [...active, ...pending])
            p.displayName.trim().toLowerCase(),
        };
        fresh = [
          for (final p in _roster!.players)
            if (!names.contains(p.name.toLowerCase())) p,
        ];
        onRoster = _roster!.players.length - fresh.length;
      }
      var newFiles = const <_File>[];
      var already = 0;
      if (_documents && _files.isNotEmpty) {
        final check = await repo.importDocuments(
          widget.groupId,
          source: _source,
          documents: [for (final f in _files) _document(f, _myName)],
          check: true,
        );
        newFiles = [
          for (final f in _files)
            if (!check.existing.contains(f.sourceId)) f,
        ];
        already = check.existing.length;
      }
      if (!mounted) return;
      setState(() {
        _eventsPreview = events;
        _newPlayers = fresh;
        _playersOnRoster = onRoster;
        _newFiles = newFiles;
        _filesImported = already;
        _previewed = true;
      });
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = _failureText(l10n, e));
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  String _failureText(AppLocalizations l10n, AppFailure e) => switch (e) {
    InvalidInput(message: 'too-many-players') => l10n.tooManyPlayers(
      Limits.playersPerGroupMax,
    ),
    _ => importFailureText(l10n, e, _source),
  };

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final g = widget.groupId;
    setState(() => _error = null);
    _setBusy(true);
    final lines = <String>[];
    final actions = <({String label, String route})>[];
    try {
      final repo = ref.read(importRepositoryProvider);
      if (_events && _hasEvents) {
        setState(() => _progress = l10n.importAddingEvents);
        final r = await repo.importEvents(
          g,
          source: _source,
          includePast: _includePast,
          dryRun: false,
          url: _ics == null ? _link.text.trim() : null,
          ics: _ics?.text,
        );
        lines.add(l10n.importDone(r.added));
        if (r.added > 0) {
          actions.add((
            label: l10n.importOpenSchedule,
            route: '/g/${g.value}/schedule',
          ));
        }
      }
      if (_players && _newPlayers.isNotEmpty) {
        setState(() => _progress = l10n.importAddingPlayers);
        var added = 0;
        final players = ref.read(playerRepositoryProvider);
        for (var i = 0; i < _newPlayers.length; i += _playersPerAdd) {
          final part = _newPlayers.sublist(
            i,
            math.min(i + _playersPerAdd, _newPlayers.length),
          );
          added += await players.addPlayers(g, [
            for (final p in part)
              NewPlayer(
                name: p.name,
                jerseyNumber: p.jerseyNumber,
                dateOfBirth: p.dateOfBirth,
              ),
          ]);
        }
        lines.add(l10n.importPlayersDone(added));
        actions.add((
          label: l10n.importOpenRoster,
          route: '/g/${g.value}/roster',
        ));
      }
      if (_documents && _newFiles.isNotEmpty) {
        final ready = <ChatImportDocument>[];
        var full = false;
        for (final (i, f) in _newFiles.indexed) {
          setState(
            () => _progress = l10n.importAddingDocuments(i, _newFiles.length),
          );
          final doc = _document(f, _myName);
          try {
            await repo.upload(
              doc.path,
              await f.file.readBytes(),
              f.contentType,
            );
            ready.add(doc);
          } on StorageFull {
            full = true;
            break;
          }
        }
        var added = 0;
        for (var i = 0; i < ready.length; i += 50) {
          final r = await repo.importDocuments(
            g,
            source: _source,
            documents: ready.sublist(i, math.min(i + 50, ready.length)),
          );
          added += r.added;
        }
        lines.add(l10n.importDocumentsDone(added));
        if (full) lines.add(l10n.importStorageFilled);
        if (added > 0) {
          actions.add((
            label: l10n.importOpenDocuments,
            route: '/g/${g.value}/documents',
          ));
        }
      }
      if (!mounted) return;
      widget.onDone(ImportReport(lines: lines, actions: actions));
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = [...lines, _failureText(l10n, e)].join('\n'));
    } finally {
      if (mounted) {
        setState(() => _progress = null);
        _setBusy(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    CheckboxListTile box({
      required bool value,
      required ValueChanged<bool>? onChanged,
      required String title,
      required String subtitle,
    }) => CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: value,
      onChanged: _busy || onChanged == null
          ? null
          : (v) {
              onChanged(v ?? false);
              _changed();
            },
      title: Text(title),
      subtitle: Text(subtitle),
    );
    final roster = _roster;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.importWhat, style: theme.textTheme.titleSmall),
        // Each kind on its own (IMPORT-2).
        box(
          value: _events,
          onChanged: (v) => _events = v,
          title: l10n.importEvents,
          subtitle: l10n.importEventsHelp,
        ),
        if (ref.watch(groupProvider(widget.groupId)).value?.hasPlayers ?? true)
          box(
            value: _players,
            onChanged: (v) => _players = v,
            title: l10n.importPlayers,
            subtitle: l10n.importPlayersHelp,
          ),
        box(
          value: _documents,
          onChanged: (v) => _documents = v,
          title: l10n.importDocuments,
          subtitle: l10n.importTeamSnapDocumentsHelp,
        ),
        box(
          value: false,
          onChanged: null,
          title: l10n.importChat,
          subtitle: l10n.importMessagesUnavailableTeamSnap,
        ),
        Text(l10n.importNoRsvps, style: muted),
        if (_events) ...[
          const SizedBox(height: Space.lg),
          Text(
            l10n.importLinkTitle(_source.label),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: Space.sm),
          Text(l10n.importTeamSnapScheduleSteps),
          const SizedBox(height: Space.md),
          CalendarLinkInput(
            link: _link,
            file: _ics,
            enabled: !_busy,
            onChanged: _changed,
            onChooseFile: () => unawaited(_chooseCalendar()),
            onRemoveFile: () {
              _ics = null;
              _changed();
            },
          ),
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
        ],
        if (_players) ...[
          const SizedBox(height: Space.lg),
          Text(l10n.importRosterTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.sm),
          Text(l10n.importTeamSnapRosterSteps),
          if (roster != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.roster),
              title: Text(_rosterName ?? ''),
              subtitle: Text(l10n.importRosterCount(roster.players.length)),
              trailing: IconButton(
                tooltip: l10n.importRemoveFile,
                icon: const Icon(AppIcons.close),
                onPressed: _busy
                    ? null
                    : () {
                        _roster = null;
                        _rosterName = null;
                        _changed();
                      },
              ),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _busy ? null : () => unawaited(_chooseRoster()),
                child: Text(l10n.importChooseRoster),
              ),
            ),
        ],
        if (_documents) ...[
          const SizedBox(height: Space.lg),
          Text(l10n.importFilesTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.sm),
          Text(l10n.importTeamSnapFilesSteps),
          for (final f in _files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(AppIcons.document),
              title: Text(f.file.name),
              subtitle: Text(formatBytes(f.file.size)),
            ),
          if (_filesUnsupported > 0)
            Text(l10n.importLeftFilesUnsupported(_filesUnsupported)),
          if (_filesTooLarge > 0)
            Text(l10n.importLeftFilesTooLarge(_filesTooLarge)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _busy ? null : () => unawaited(_chooseFiles()),
              child: Text(
                _files.isEmpty
                    ? l10n.importChooseFiles
                    : l10n.importChangeFiles,
              ),
            ),
          ),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: Space.sm),
          Text(error, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: Space.lg),
        if (_progress case final p?) ...[
          Text(p),
          const SizedBox(height: Space.sm),
          const LinearProgressIndicator(),
        ] else if (!_previewed)
          FilledButton(
            onPressed: _busy || !_ready ? null : () => unawaited(_preview()),
            child: _busy ? const ButtonSpinner() : Text(l10n.importPreview),
          )
        else ...[
          _TeamSnapPreview(
            events: _eventsPreview,
            players: _players ? _newPlayers : null,
            playersOnRoster: _playersOnRoster,
            roster: roster,
            files: _documents ? _newFiles : null,
            filesImported: _filesImported,
            freeBytes: _freeBytes(),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_import()),
            child: _busy ? const ButtonSpinner() : Text(l10n.importStart),
          ),
        ],
      ],
    );
  }

  /// The team's free storage, or null before the team is read.
  int? _freeBytes() {
    final team = ref.watch(groupProvider(widget.groupId)).value;
    if (team == null || team.storageQuotaBytes <= 0) return null;
    return math.max(0, team.storageQuotaBytes - team.storageBytes);
  }
}

/// What importing would bring from TeamSnap, kind by kind (IMPORT-3).
class _TeamSnapPreview extends StatelessWidget {
  const new({
    required this.events,
    required this.players,
    required this.playersOnRoster,
    required this.roster,
    required this.files,
    required this.filesImported,
    required this.freeBytes,
  });

  final EventImportResult? events;
  final List<RosterRow>? players;
  final int playersOnRoster;
  final RosterFile? roster;
  final List<_File>? files;
  final int filesImported;
  final int? freeBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ps = players;
    final fs = files;
    final r = roster;
    final bytes = (fs ?? const <_File>[]).fold(0, (n, f) => n + f.file.size);
    final free = freeBytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (events case final e?) ...[
          EventPreview(result: e, source: ImportSource.teamsnap),
          const SizedBox(height: Space.md),
        ],
        if (ps != null && r != null) ...[
          Text(
            l10n.importPlayersToAdd(ps.length),
            style: theme.textTheme.titleMedium,
          ),
          for (final p in ps.take(8))
            Text([p.name, if (p.jerseyNumber case final n?) '#$n'].join(' ')),
          if (ps.length > 8) Text(l10n.importAndMore(ps.length - 8)),
          if (playersOnRoster > 0) Text(l10n.importOnRoster(playersOnRoster)),
          if (r.nonPlayers > 0) Text(l10n.importNonPlayersLeft(r.nonPlayers)),
          if (r.datesUnreadable > 0)
            Text(l10n.importDatesUnreadable(r.datesUnreadable)),
          const SizedBox(height: Space.md),
        ],
        if (fs != null) ...[
          Text(
            l10n.importDocumentsToAdd(fs.length),
            style: theme.textTheme.titleMedium,
          ),
          if (filesImported > 0) Text(l10n.importAlready(filesImported)),
          if (bytes > 0)
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
        const SizedBox(height: Space.sm),
        Text(l10n.importSkipsRepeats, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
