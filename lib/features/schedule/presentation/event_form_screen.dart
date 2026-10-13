import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/presentation/event_actions.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Waits for what the form starts from (the team, and the event being
/// edited or duplicated), then shows [EventFormScreen].
class EventFormRoute extends ConsumerWidget {
  const new({
    required this.groupId,
    this.eventId,
    this.fromEventId,
    this.scope,
    super.key,
  });

  final GroupId groupId;

  /// Editing this event.
  final EventId? eventId;

  /// Duplicating this event (SCHED-3).
  final EventId? fromEventId;

  /// For a series event: this one, or this and the following (SCHED-6).
  final SeriesScope? scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final sourceId = eventId ?? fromEventId;
    final source = sourceId == null ? null : ref.watch(eventProvider(sourceId));
    final series = source?.value?.seriesId == null || eventId == null
        ? null
        : ref.watch(eventSeriesProvider(source!.value!.seriesId!));
    final ready =
        group != null &&
        (source == null || source.hasValue) &&
        (series == null || series.hasValue);
    if (!ready) {
      return Scaffold(appBar: AppBar(), body: const SkeletonList());
    }
    if (sourceId != null && source!.value == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.eventNotFound)),
      );
    }
    return EventFormScreen(
      group: group,
      editing: eventId == null ? null : source!.value,
      duplicateOf: fromEventId == null ? null : source!.value,
      series: series?.value,
      scope: scope,
    );
  }
}

/// New, edit, and Duplicate (SCHED-3, SCHED-6): type, title (games fill
/// in "vs. Opponent"), date, times or all day, time zone, place, notes,
/// game fields, RSVPs and deadline, reminders, Notify team, Post to chat,
/// and Repeat with its dates, which a tap skips.
class EventFormScreen extends ConsumerStatefulWidget {
  const new({
    required this.group,
    this.editing,
    this.duplicateOf,
    this.series,
    this.scope,
    super.key,
  });

  final Group group;
  final Event? editing;
  final Event? duplicateOf;
  final EventSeries? series;
  final SeriesScope? scope;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  late EventDraft _draft;
  late final EventDraft _initial;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _place = TextEditingController();
  final _address = TextEditingController();
  final _opponent = TextEditingController();
  final _dateFocus = FocusNode();
  bool _saving = false;
  bool _tried = false;

  Event? get _editing => widget.editing;
  bool get _isNew => _editing == null;
  bool get _seriesEdit => _editing?.inSeries ?? false;
  bool get _following => _seriesEdit && widget.scope == SeriesScope.following;

  /// Repeat shows on new events and on "This and following" edits.
  bool get _canRepeat => _isNew || _following;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    final source = _editing ?? widget.duplicateOf;
    if (source != null) {
      _draft = EventDraft.fromEvent(
        source,
        duplicate: widget.duplicateOf != null,
      );
      final from = _editing?.seriesDate;
      if (_following && widget.series != null && from != null) {
        final old = widget.series!.recurrence;
        // The rule starts again on this event's series date, where the
        // server starts it, and keeps the whole series' count, less the
        // events before (SCHED-6).
        _draft = _draft.copyWith(
          repeat: RepeatRule.fromRecurrence(old),
          seriesFrom: from,
          countBefore: datesBefore(old, from),
        );
      }
    } else {
      final now = ZonedTime.wallClock(group.timeZone, DateTime.now());
      _draft = EventDraft(
        timeZone: group.timeZone,
        date: DateTime.utc(now.year, now.month, now.day),
        reminderOffsets: group.settings.defaultReminderOffsets,
      );
    }
    _initial = _draft;
    _title.text = _draft.title;
    _notes.text = _draft.description;
    _place.text = _draft.locationName;
    _address.text = _draft.locationAddress;
    _opponent.text = _draft.opponent;
    // On a duplicate the date is empty and gets focus (SCHED-3).
    if (widget.duplicateOf != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dateFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _notes, _place, _address, _opponent]) {
      c.dispose();
    }
    _dateFocus.dispose();
    super.dispose();
  }

  /// The draft with what's typed in the text fields.
  EventDraft get _current => _draft.copyWith(
    title: _title.text,
    description: _notes.text,
    locationName: _place.text,
    locationAddress: _address.text,
    opponent: _opponent.text,
  );

  void _set(EventDraft Function(EventDraft d) change) =>
      setState(() => _draft = change(_draft));

  void _setRepeat(RepeatRule Function(RepeatRule r) change) =>
      _set((d) => d.copyWith(repeat: change(d.repeat ?? const RepeatRule())));

  bool get _touched => _current != _initial;

  Future<void> _leave() async {
    if (!_touched) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.eventDiscardTitle,
      confirmLabel: l10n.eventDiscard,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  DateTime _localDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Future<DateTime?> _pickDate(DateTime? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _localDay(initial ?? now),
      // Past events can be added too, such as last season's.
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    return picked == null ? null : _utcDay(picked);
  }

  Future<int?> _pickTime(int minutes) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<void> _pickDeadline() async {
    final d = _current;
    final start = d.startAt;
    final day = await _pickDate(
      start == null ? null : addDays(_utcDay(start), -1),
    );
    if (day == null || !mounted) return;
    final minutes = await _pickTime(d.allDay ? 12 * 60 : d.startMinutes);
    if (minutes == null) return;
    _set(
      (d) => d.copyWith(
        rsvpDeadline: ZonedTime.instantOf(d.timeZone, day, minutes),
        deadlineDaysBefore: null,
        deadlineMinutes: null,
      ),
    );
  }

  Future<void> _pickTimeZone() async {
    final l10n = AppLocalizations.of(context);
    final zones = await ref.read(timeZonesProvider).available();
    if (!mounted) return;
    final all = {...zones, _draft.timeZone, widget.group.timeZone}.toList()
      ..sort();
    final picked = await showAdaptiveSheet<String>(
      context,
      builder: (_) => _TimeZoneList(zones: all, title: l10n.eventTimeZone),
    );
    if (picked != null) _set((d) => d.copyWith(timeZone: picked));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = _current;
    setState(() => _tried = true);
    final problem = draft.problemAt(DateTime.now());
    if (problem != null) {
      showAppSnackBar(context, _problemText(l10n, problem));
      if (problem == DraftProblem.date) _dateFocus.requestFocus();
      return;
    }
    final group = widget.group;
    if (_isNew && group.storageFull) {
      showStorageFull(context);
      return;
    }
    final repo = ref.read(eventRepositoryProvider);
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final editing = _editing;
      if (editing == null) {
        if (draft.repeat == null) {
          final id = await repo.createEvent(
            group.id,
            draft,
            createdBy: UserId(uid),
          );
          if (!mounted) return;
          context.pushReplacement(
            '/g/${group.id.value}/schedule/e/${id.value}',
          );
        } else {
          final result = await repo.createSeries(
            group.id,
            draft.recurrence!,
            draft.template,
          );
          if (!mounted) return;
          showAppSnackBar(
            context,
            l10n.seriesCreated(eventCount(l10n, draft.type, result.created)),
          );
          Navigator.of(context).pop();
        }
        return;
      }
      if (!editing.inSeries) {
        await repo.updateEvent(editing, draft);
      } else if (!_following) {
        await repo.updateSeries(
          editing.id,
          SeriesScope.thisEvent,
          draft.template,
          date: dateKey(draft.date!),
        );
      } else {
        // Say what goes before it goes (SCHED-6).
        final dry = await repo.updateSeries(
          editing.id,
          SeriesScope.following,
          draft.template,
          recurrence: draft.recurrence,
          dryRun: true,
        );
        if (!mounted) return;
        final changes = seriesChangeLine(l10n, draft.type, dry);
        if (changes != null) {
          final ok = await showConfirmDialog(
            context,
            title: l10n.seriesSaveTitle,
            message: changes,
            confirmLabel: l10n.save,
            cancelLabel: l10n.cancel,
            destructive: dry.removed > 0,
          );
          if (!ok || !mounted) return;
        }
        await repo.updateSeries(
          editing.id,
          SeriesScope.following,
          draft.template,
          recurrence: draft.recurrence,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) showSaveFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _problemText(AppLocalizations l10n, DraftProblem p) => switch (p) {
    DraftProblem.title => l10n.eventProblemTitle,
    DraftProblem.date => l10n.eventProblemDate,
    DraftProblem.deadline => l10n.eventProblemDeadline,
    DraftProblem.repeat => l10n.eventProblemRepeat,
    DraftProblem.notes ||
    DraftProblem.location ||
    DraftProblem.opponent ||
    DraftProblem.reminders => l10n.eventTooLong,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = _current;
    final deadline = d.deadline;
    final title = _isNew ? l10n.eventNew : l10n.eventEditTitle;
    final missingDate = d.date == null;

    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return PopScope(
      canPop: !_touched,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.cancel,
            icon: const Icon(AppIcons.close),
            onPressed: () => unawaited(_leave()),
          ),
          title: Text(title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: FilledButton(
                onPressed: _saving ? null : () => unawaited(_save()),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                if (_saving) const LinearProgressIndicator(),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.xs,
                  children: [
                    for (final t in EventType.values)
                      ChoiceChip(
                        avatar: Icon(typeIcon(t), size: 18),
                        label: Text(typeLabel(l10n, t)),
                        selected: d.type == t,
                        onSelected: (_) => _set((d) => d.copyWith(type: t)),
                      ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                if (d.isGame) ...[
                  TextField(
                    controller: _opponent,
                    maxLength: Limits.opponentMax,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.eventOpponent,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Space.sm),
                  SegmentedButton<HomeAway>(
                    emptySelectionAllowed: true,
                    segments: [
                      ButtonSegment(
                        value: HomeAway.home,
                        label: Text(l10n.eventHome),
                      ),
                      ButtonSegment(
                        value: HomeAway.away,
                        label: Text(l10n.eventAway),
                      ),
                    ],
                    selected: {?d.homeAway},
                    onSelectionChanged: (s) => _set(
                      (d) => d.copyWith(homeAway: s.isEmpty ? null : s.first),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                ],
                TextField(
                  controller: _title,
                  maxLength: Limits.eventTitleMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.eventTitle,
                    border: const OutlineInputBorder(),
                    // Left blank, a game is "vs. Eagles" (SCHED-3).
                    hintText: d.isGame && d.effectiveTitle.isNotEmpty
                        ? autoGameTitle(d.opponent, d.homeAway)
                        : null,
                    errorText: _tried && d.effectiveTitle.isEmpty
                        ? l10n.eventProblemTitle
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                section(l10n.eventWhen),
                Focus(
                  focusNode: _dateFocus,
                  child: Builder(
                    builder: (context) {
                      final focused = Focus.of(context).hasFocus;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(AppIcons.event),
                        title: Text(
                          missingDate
                              ? l10n.eventPickDate
                              : dayLabel(l10n, d.date!),
                          style: missingDate && (_tried || focused)
                              ? TextStyle(color: scheme.error)
                              : null,
                        ),
                        subtitle: Text(l10n.eventDate),
                        selected: focused,
                        trailing: const Icon(AppIcons.edit),
                        onTap: () async {
                          final day = await _pickDate(d.date);
                          if (day != null) {
                            _set((d) => d.copyWith(date: day));
                          }
                        },
                      );
                    },
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.eventAllDay),
                  value: d.allDay,
                  onChanged: (v) => _set((d) => d.copyWith(allDay: v)),
                ),
                // A series event is one day; "This event" can move it but
                // not stretch it.
                if (d.allDay && !_repeats(d) && !_seriesEdit)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.event),
                    title: Text(
                      d.endDate == null
                          ? l10n.eventSameDay
                          : dayLabel(l10n, d.endDate!),
                    ),
                    subtitle: Text(l10n.eventLastDay),
                    trailing: const Icon(AppIcons.edit),
                    onTap: () async {
                      final day = await _pickDate(d.lastDay);
                      if (day != null) {
                        _set(
                          (d) =>
                              d.copyWith(endDate: day == d.date ? null : day),
                        );
                      }
                    },
                  ),
                if (!d.allDay) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.time),
                    title: Text(_clock(d.startMinutes)),
                    subtitle: Text(l10n.eventStarts),
                    trailing: const Icon(AppIcons.edit),
                    onTap: () async {
                      final m = await _pickTime(d.startMinutes);
                      if (m != null) {
                        // Keep the length when the start moves.
                        final length =
                            (d.endMinutes - d.startMinutes) % (24 * 60);
                        _set(
                          (d) => d.copyWith(
                            startMinutes: m,
                            endMinutes: (m + length) % (24 * 60),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.time),
                    title: Text(_clock(d.endMinutes)),
                    subtitle: Text(
                      d.endMinutes <= d.startMinutes
                          ? '${l10n.eventEnds} · ${l10n.eventEndsNextDay}'
                          : l10n.eventEnds,
                    ),
                    trailing: const Icon(AppIcons.edit),
                    onTap: () async {
                      final m = await _pickTime(d.endMinutes);
                      if (m != null) _set((d) => d.copyWith(endMinutes: m));
                    },
                  ),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.timeZone),
                  title: Text(d.timeZone.replaceAll('_', ' ')),
                  subtitle: Text(l10n.eventTimeZone),
                  trailing: const Icon(AppIcons.edit),
                  onTap: () => unawaited(_pickTimeZone()),
                ),
                if (d.isGame)
                  DropdownButtonFormField<int?>(
                    initialValue: d.arriveMinutesBefore,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.eventArriveEarly,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(child: Text(l10n.eventArriveNone)),
                      for (final m in const [10, 15, 20, 30, 45, 60, 90, 120])
                        DropdownMenuItem(
                          value: m,
                          child: Text(l10n.eventArrive(m)),
                        ),
                    ],
                    onChanged: (m) =>
                        _set((d) => d.copyWith(arriveMinutesBefore: m)),
                  ),
                if (_canRepeat) _repeatSection(context, d),
                section(l10n.eventWhere),
                TextField(
                  controller: _place,
                  maxLength: Limits.locationNameMax,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.eventPlace,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.sm),
                TextField(
                  controller: _address,
                  maxLength: Limits.locationAddressMax,
                  decoration: InputDecoration(
                    labelText: l10n.eventAddress,
                    border: const OutlineInputBorder(),
                    suffixIcon: d.location == null
                        ? null
                        : IconButton(
                            tooltip: l10n.eventOpenInMaps,
                            icon: const Icon(AppIcons.directions),
                            onPressed: () =>
                                unawaited(openDirections(ref, d.location!)),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.sm),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: Limits.eventNotesMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.eventNotes,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                section(l10n.eventRsvpTitle),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.eventTakeRsvps),
                  value: d.rsvpEnabled,
                  onChanged: (v) => _set((d) => d.copyWith(rsvpEnabled: v)),
                ),
                // Series events have no deadline (ARCH §6.2).
                if (d.rsvpEnabled && d.repeat == null && !_seriesEdit)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.rsvp),
                    title: Text(
                      deadline == null
                          ? (d.deadlineDaysBefore != null
                                ? l10n.eventDeadlineAfterDate
                                : l10n.eventNoDeadline)
                          : '${dayLabel(l10n, ZonedTime.wallClock(d.timeZone, deadline))} '
                                '${timeIn(l10n, deadline, d.timeZone)}',
                      style:
                          _tried &&
                              d.problemAt(DateTime.now()) ==
                                  DraftProblem.deadline
                          ? TextStyle(color: scheme.error)
                          : null,
                    ),
                    subtitle: Text(l10n.eventRsvpDeadline),
                    trailing:
                        d.rsvpDeadline == null && d.deadlineDaysBefore == null
                        ? const Icon(AppIcons.edit)
                        : IconButton(
                            tooltip: l10n.eventClearDeadline,
                            icon: const Icon(AppIcons.close),
                            onPressed: () => _set(
                              (d) => d.copyWith(
                                rsvpDeadline: null,
                                deadlineDaysBefore: null,
                                deadlineMinutes: null,
                              ),
                            ),
                          ),
                    onTap: () => unawaited(_pickDeadline()),
                  ),
                section(l10n.eventReminders),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.xs,
                  children: [
                    for (final m in reminderOffsetsMinutes)
                      FilterChip(
                        label: Text(reminderLabel(l10n, m)),
                        selected: d.reminderOffsets.contains(m),
                        onSelected: (on) => _set(
                          (d) => d.copyWith(
                            reminderOffsets: on
                                ? [...d.reminderOffsets, m]
                                : [
                                    for (final o in d.reminderOffsets)
                                      if (o != m) o,
                                  ],
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  l10n.eventRemindersHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                // Read once, when the event is made (ARCH §6.4).
                if (_isNew) ...[
                  const SizedBox(height: Space.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.eventNotifyTeam),
                    value: d.notifyTeam,
                    onChanged: (v) => _set((d) => d.copyWith(notifyTeam: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.eventPostToChat),
                    value: d.postToChat,
                    onChanged: (v) => _set((d) => d.copyWith(postToChat: v)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Multi-day all-day events don't repeat; a repeating one is one day.
  bool _repeats(EventDraft d) => d.repeat != null;

  String _clock(int minutes) => MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

  /// Repeat (SCHED-3): daily every N days, or weekly on days every N
  /// weeks; ends on a date or after N events; the dates it makes, which a
  /// tap skips, under "24 practices · Tue and Thu · Oct 13 – Dec 17".
  Widget _repeatSection(BuildContext context, EventDraft d) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = d.repeat;
    final rule = d.savedRecurrence;
    final dates = d.seriesDates;
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    // ISO weekdays in the locale's order (Sunday first in the US).
    final weekdays = [for (var i = 0; i < 7; i++) (firstDay + i + 6) % 7 + 1];
    final repeatValue = r?.freq;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.md),
        DropdownButtonFormField<RepeatFreq?>(
          key: ValueKey('repeat-${r?.freq}'),
          initialValue: repeatValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.eventRepeat,
            prefixIcon: const Icon(AppIcons.repeat),
            border: const OutlineInputBorder(),
          ),
          items: [
            // "This and following" keeps it a series.
            if (!_following) DropdownMenuItem(child: Text(l10n.repeatNever)),
            DropdownMenuItem(
              value: RepeatFreq.daily,
              child: Text(l10n.repeatDaily),
            ),
            DropdownMenuItem(
              value: RepeatFreq.weekly,
              child: Text(l10n.repeatWeekly),
            ),
          ],
          onChanged: (f) => _set((d) {
            if (f == null) return d.copyWith(repeat: null);
            final date = d.date;
            final current = d.repeat;
            return d.copyWith(
              allDay: d.allDay,
              endDate: null,
              repeat: (current ?? const RepeatRule()).copyWith(
                freq: f,
                byWeekday: (current?.byWeekday.isEmpty ?? true) && date != null
                    ? [date.weekday]
                    : current?.byWeekday ?? const [],
                untilDate:
                    current?.untilDate ??
                    (date == null ? null : dateKey(addDays(date, 8 * 7 - 1))),
              ),
            );
          }),
        ),
        if (r != null) ...[
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Text(l10n.repeatEvery),
              const SizedBox(width: Space.sm),
              DropdownButton<int>(
                value: r.interval,
                items: [
                  for (var n = 1; n <= Limits.seriesIntervalMax; n++)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) =>
                    _setRepeat((r) => r.copyWith(interval: n ?? 1)),
              ),
              const SizedBox(width: Space.sm),
              Text(
                r.freq == RepeatFreq.daily
                    ? l10n.repeatDayUnit(r.interval)
                    : l10n.repeatWeekUnit(r.interval),
              ),
            ],
          ),
          if (r.freq == RepeatFreq.weekly)
            Wrap(
              spacing: Space.xs,
              children: [
                for (final w in weekdays)
                  FilterChip(
                    label: Text(weekdayShort(l10n, w)),
                    selected: r.byWeekday.contains(w),
                    onSelected: (on) => _setRepeat(
                      (r) => r.copyWith(
                        byWeekday: on
                            ? [...r.byWeekday, w]
                            : [
                                for (final x in r.byWeekday)
                                  if (x != w) x,
                              ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Text(l10n.repeatEnds),
              const SizedBox(width: Space.md),
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.repeatEndsOn)),
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.repeatEndsAfter),
                    ),
                  ],
                  selected: {r.endsOnDate},
                  onSelectionChanged: (s) =>
                      _setRepeat((r) => r.copyWith(endsOnDate: s.first)),
                ),
              ),
            ],
          ),
          if (r.endsOnDate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.event),
              title: Text(
                r.untilDate == null
                    ? l10n.eventPickDate
                    : dayLabel(l10n, parseDateKey(r.untilDate!)),
              ),
              subtitle: Text(l10n.repeatUntil),
              trailing: const Icon(AppIcons.edit),
              onTap: () async {
                final day = await _pickDate(
                  r.untilDate == null ? d.date : parseDateKey(r.untilDate!),
                );
                if (day != null) {
                  _setRepeat((r) => r.copyWith(untilDate: dateKey(day)));
                }
              },
            )
          else
            Row(
              children: [
                IconButton(
                  tooltip: l10n.repeatFewer,
                  icon: const Icon(Icons.remove),
                  onPressed: r.count > 1
                      ? () => _setRepeat((r) => r.copyWith(count: r.count - 1))
                      : null,
                ),
                Text(l10n.repeatCount(r.count)),
                IconButton(
                  tooltip: l10n.repeatMore,
                  icon: const Icon(AppIcons.add),
                  onPressed: r.count < Limits.seriesEventsMax
                      ? () => _setRepeat((r) => r.copyWith(count: r.count + 1))
                      : null,
                ),
              ],
            ),
          if (rule != null && dates != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              seriesSummary(l10n, d.type, rule, dates.dates),
              style: theme.textTheme.titleSmall?.copyWith(
                color: dates.dates.isEmpty ? scheme.error : null,
              ),
            ),
            if (dates.dates.isNotEmpty)
              Text(
                l10n.repeatSkipHelp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final key in dates.dates)
                  ActionChip(
                    label: Text(dayLabel(l10n, parseDateKey(key))),
                    tooltip: l10n.repeatSkipDate,
                    onPressed: r.skipDates.length >= Limits.seriesSkipDatesMax
                        ? null
                        : () => _setRepeat(
                            (r) => r.copyWith(skipDates: [...r.skipDates, key]),
                          ),
                  ),
              ],
            ),
            if (dates.skipped.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Text(l10n.repeatSkipped, style: theme.textTheme.labelMedium),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final key in dates.skipped)
                    ActionChip(
                      label: Text(
                        dayLabel(l10n, parseDateKey(key)),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      tooltip: l10n.repeatRestoreDate,
                      onPressed: () => _setRepeat(
                        (r) => r.copyWith(
                          skipDates: [
                            for (final s in r.skipDates)
                              if (s != key) s,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ],
    );
  }
}

/// A searchable list of time zones.
class _TimeZoneList extends StatefulWidget {
  const new({required this.zones, required this.title});

  final List<String> zones;
  final String title;

  @override
  State<_TimeZoneList> createState() => _TimeZoneListState();
}

class _TimeZoneListState extends State<_TimeZoneList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _query.toLowerCase().replaceAll(' ', '_');
    final shown = [
      for (final z in widget.zones)
        if (z.toLowerCase().contains(q)) z,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.title,
              hintText: l10n.eventTimeZoneSearch,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final z in shown)
                ListTile(
                  title: Text(z.replaceAll('_', ' ')),
                  onTap: () => Navigator.of(context).pop(z),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
