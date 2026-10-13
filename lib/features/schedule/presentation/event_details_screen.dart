import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/event_actions.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// An event's page (SCHED-4): every field, big Going / Maybe / Not going
/// buttons (one set per player for guardians, PLAYER-6), who's coming,
/// Add to calendar, Share, Directions, and for admins Edit, Duplicate,
/// Cancel, Delete, and Set RSVP for someone.
class EventDetailsScreen extends ConsumerWidget {
  const new({required this.groupId, required this.eventId, super.key});

  final GroupId groupId;
  final EventId eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eventProvider(eventId));
    final event = async.value;
    final group = ref.watch(groupProvider(groupId)).value;
    final zone = ref.watch(viewerTimeZoneProvider).value;
    if (event == null || group == null || zone == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading || group == null || zone == null
            ? const SkeletonList()
            : EmptyState(icon: AppIcons.event, message: l10n.eventNotFound),
      );
    }
    final me = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canManage = canManageEvent(event, group, me, superAdmin: superAdmin);
    final canCreate = canCreateEvents(group, me);

    Future<void> onMenu(_Action a) async {
      switch (a) {
        case _Action.edit:
          var scope = '';
          if (event.inSeries) {
            final s = await askSeriesScope(context, l10n.seriesEditTitle);
            if (s == null || !context.mounted) return;
            scope = '?scope=${s.value}';
          }
          unawaited(
            context.push(
              '/g/${groupId.value}/schedule/e/${eventId.value}/edit$scope',
            ),
          );
        case _Action.duplicate:
          if (group.storageFull) {
            showSaveFailure(context, const StorageFull());
            return;
          }
          unawaited(
            context.push(
              '/g/${groupId.value}/schedule/new?from=${eventId.value}',
            ),
          );
        case _Action.cancel:
          await cancelEventFlow(context, ref, event);
        case _Action.delete:
          final deleted = await deleteEventFlow(context, ref, event);
          if (deleted && context.mounted) {
            showAppSnackBar(context, l10n.eventDeleted);
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/g/${groupId.value}/schedule');
            }
          }
        case _Action.setRsvp:
          await _setRsvpForSomeone(context, ref, event, group);
      }
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.eventAddToCalendar,
            icon: const Icon(AppIcons.addToCalendar),
            onPressed: () => unawaited(addToCalendar(context, ref, event)),
          ),
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(AppIcons.share),
            onPressed: () => unawaited(shareEvent(context, ref, event)),
          ),
          if (canManage || canCreate)
            PopupMenuButton<_Action>(
              tooltip: l10n.eventMoreActions,
              onSelected: (a) => unawaited(onMenu(a)),
              itemBuilder: (_) => [
                if (canManage)
                  PopupMenuItem(
                    value: _Action.edit,
                    child: Text(l10n.eventEdit),
                  ),
                if (canCreate)
                  PopupMenuItem(
                    value: _Action.duplicate,
                    child: Text(l10n.eventDuplicate),
                  ),
                if (canManage && event.takesRsvps && me != null && me.isAdmin)
                  PopupMenuItem(
                    value: _Action.setRsvp,
                    child: Text(l10n.eventSetRsvpFor),
                  ),
                if (canManage && !event.isCanceled)
                  PopupMenuItem(
                    value: _Action.cancel,
                    child: Text(l10n.eventCancel),
                  ),
                if (canManage)
                  PopupMenuItem(
                    value: _Action.delete,
                    child: Text(l10n.eventDelete),
                  ),
              ],
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _Details(event: event, group: group, me: me, zone: zone),
        ),
      ),
    );
  }
}

enum _Action { edit, duplicate, setRsvp, cancel, delete }

class _Details extends ConsumerWidget {
  const new({
    required this.event,
    required this.group,
    required this.me,
    required this.zone,
  });

  final Event event;
  final Group group;
  final Membership? me;
  final String zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = typeColor(context, event.type);
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final series = event.seriesId == null
        ? null
        : ref.watch(eventSeriesProvider(event.seriesId!)).value;
    final otherZone = otherZoneLine(l10n, event, zone);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget line(IconData icon, Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.md),
          Expanded(child: child),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(typeIcon(event.type), size: 18, color: color),
                  const SizedBox(width: Space.xs),
                  Text(
                    typeLabel(l10n, event.type),
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                  if (event.isCanceled) ...[
                    const SizedBox(width: Space.sm),
                    const CanceledBadge(),
                  ],
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(
                event.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  decoration: event.isCanceled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
        ),
        line(
          AppIcons.time,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeRange(l10n, event, zone, withDay: true)),
              if (otherZone != null) Text(otherZone, style: muted),
              if (event.isGame && event.arriveMinutesBefore != null)
                Text(
                  l10n.eventArrive(event.arriveMinutesBefore!),
                  style: muted,
                ),
            ],
          ),
        ),
        if (series != null)
          line(AppIcons.repeat, Text(repeatsLine(l10n, series.recurrence))),
        if (event.isGame &&
            ((event.opponent?.isNotEmpty ?? false) || event.homeAway != null))
          line(
            AppIcons.game,
            Text(
              [
                if (event.opponent?.isNotEmpty ?? false)
                  l10n.eventOpponentLine(event.opponent!),
                if (event.homeAway == HomeAway.home) l10n.eventHome,
                if (event.homeAway == HomeAway.away) l10n.eventAway,
              ].join(' · '),
            ),
          ),
        if (event.location case final loc?)
          line(
            AppIcons.location,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loc.name.isNotEmpty) Text(loc.name),
                if (loc.address.isNotEmpty) Text(loc.address, style: muted),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => unawaited(openDirections(ref, loc)),
                    icon: const Icon(AppIcons.directions, size: 18),
                    label: Text(l10n.eventDirections),
                  ),
                ),
              ],
            ),
          ),
        if (event.description.isNotEmpty)
          line(AppIcons.notes, SelectableText(event.description)),
        if (event.reminderOffsets.isNotEmpty)
          line(
            AppIcons.reminder,
            Text(
              l10n.eventRemindersLine(
                joinAnd(l10n, [
                  for (final o in event.reminderOffsets) reminderLabel(l10n, o),
                ]),
              ),
            ),
          ),
        const Divider(height: Space.xl),
        _RsvpSection(event: event, group: group, me: me),
      ],
    );
  }
}

/// My answer buttons, the counts, and who's coming (SCHED-4, SCHED-5).
class _RsvpSection extends ConsumerWidget {
  const new({required this.event, required this.group, required this.me});

  final Event event;
  final Group group;
  final Membership? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Space.xs),
      child: child,
    );

    if (!event.rsvpEnabled) {
      return padded(Text(l10n.eventRsvpsOff, style: muted));
    }

    final now = DateTime.now();
    final zone = ref.watch(viewerTimeZoneProvider).value ?? event.timeZone;
    final rsvps =
        ref.watch(eventRsvpsProvider(group.id, event.id)).value ?? const [];
    final roster = ref.watch(rosterProvider(group.id)).value ?? const [];
    final players = event.forPlayers
        ? ref.watch(playersProvider(group.id)).value ?? const []
        : const <Never>[];
    final mine = ref.watch(myParticipantsProvider(group.id));
    final open = canAnswerNow(event, group, me, now);
    final isAdmin = me?.isAdmin ?? false;
    final allowMaybe = group.settings.allowMaybe;
    final everyone = eventParticipants(event, roster, players);

    final myUid = UserId(ref.watch(authUserProvider).value?.uid ?? '');
    // Admins set answers, but on youth events only their own among the
    // coaches (Q14).
    final canSet = isAdmin && event.takesRsvps && !group.isArchived;
    VoidCallback? setFor(Participant p) =>
        canSet && canSetRsvpFor(event, p, myUid)
        ? () => unawaited(_setRsvpFor(context, ref, event, group, p))
        : null;

    String nameOf(String uid) =>
        roster.where((m) => m.uid.value == uid).firstOrNull?.shortName ??
        l10n.formerMember;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        padded(Text(l10n.eventRsvpTitle, style: theme.textTheme.titleMedium)),
        if (event.isCanceled)
          padded(Text(l10n.eventRsvpClosed, style: muted))
        else if (event.rsvpDeadline != null)
          padded(
            Text(
              event.deadlinePassedAt(now)
                  ? l10n.eventDeadlinePassed
                  : l10n.eventDeadlineOn(
                      '${dayLabel(l10n, ZonedTime.wallClock(zone, event.rsvpDeadline!))} '
                      '${timeIn(l10n, event.rsvpDeadline!, zone)}',
                    ),
              style: muted,
            ),
          ),
        // Canceled events take no answers (SCHED-7).
        if (!event.isCanceled)
          for (final p in mine)
            padded(
              RsvpButtons(
                event: event,
                participant: p,
                answer: answerOf(rsvps, p.id),
                label: mine.length > 1 || p.isPlayer
                    ? (p.isPlayer ? p.shownName : l10n.eventYou)
                    : null,
                enabled: open,
                allowMaybe: allowMaybe,
              ),
            ),
        padded(
          Text(
            event.forPlayers
                ? playerCountsText(l10n, event, players: players.length)
                : countsText(l10n, event.rsvpCounts, allowMaybe: allowMaybe),
            style: theme.textTheme.labelLarge,
          ),
        ),
        _AttendeeGroups(
          people: everyone.main,
          rsvps: rsvps,
          allowMaybe: allowMaybe,
          nameOf: nameOf,
          onTap: setFor,
        ),
        if (everyone.staff.isNotEmpty) ...[
          padded(Text(l10n.eventCoaches, style: theme.textTheme.titleSmall)),
          _AttendeeGroups(
            people: everyone.staff,
            rsvps: rsvps,
            allowMaybe: allowMaybe,
            nameOf: nameOf,
            onTap: setFor,
          ),
        ],
      ],
    );
  }
}

/// Big Going / Maybe / Not going buttons for one person, with an optional
/// note ("Leaving at halftime"). Tapping the chosen answer again keeps it.
class RsvpButtons extends ConsumerWidget {
  const new({
    required this.event,
    required this.participant,
    required this.answer,
    required this.enabled,
    this.label,
    this.allowMaybe = true,
    this.compact = false,
    super.key,
  });

  final Event event;
  final Participant participant;
  final Rsvp? answer;
  final bool enabled;

  /// "Emma #7" for a player, "You" beside players; null when it's only me.
  final String? label;
  final bool allowMaybe;

  /// The chat card's smaller buttons (SPEC §5.4): no icons and no note,
  /// which the event's page has.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = answer?.status;
    final statuses = [
      RsvpStatus.going,
      if (allowMaybe || current == RsvpStatus.maybe) RsvpStatus.maybe,
      RsvpStatus.notGoing,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.only(
              top: compact ? Space.xs : Space.sm,
              bottom: Space.xs,
            ),
            child: Text(label!, style: theme.textTheme.titleSmall),
          ),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<RsvpStatus>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (final s in statuses)
                ButtonSegment(
                  value: s,
                  icon: compact ? null : Icon(statusIcon(s)),
                  label: Text(statusLabel(l10n, s)),
                ),
            ],
            selected: {?current},
            style: SegmentedButton.styleFrom(
              // Still a full 48 px tap target on the card.
              minimumSize: Size(0, compact ? 48 : 52),
              selectedBackgroundColor: current == null
                  ? null
                  : statusColor(context, current).withValues(alpha: 0.18),
            ),
            onSelectionChanged: enabled
                ? (s) {
                    if (s.isEmpty) return;
                    unawaited(
                      _answer(context, ref, s.first, answer?.note ?? ''),
                    );
                  }
                : null,
          ),
        ),
        if (!compact)
          Row(
            children: [
              if (answer?.note.isNotEmpty ?? false)
                Expanded(
                  child: Text(
                    answer!.note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (enabled && current != null)
                TextButton(
                  onPressed: () => unawaited(_editNote(context, ref, current)),
                  child: Text(
                    answer?.note.isNotEmpty ?? false
                        ? l10n.eventEditNote
                        : l10n.eventAddNote,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    RsvpStatus status,
    String note,
  ) => setRsvpWithFeedback(
    context,
    ref,
    event,
    RsvpAnswer(participant: participant, status: status, note: note),
  );

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    RsvpStatus status,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: answer?.note ?? ''),
    );
    if (note == null || !context.mounted) return;
    await _answer(context, ref, status, note);
  }
}

/// Writes an answer and says so if it's refused or fails.
Future<void> setRsvpWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Event event,
  RsvpAnswer answer,
) async {
  final l10n = AppLocalizations.of(context);
  final uid = ref.read(authUserProvider).value?.uid;
  if (uid == null) return;
  try {
    await ref
        .read(rsvpRepositoryProvider)
        .setRsvp(event, answer, by: UserId(uid));
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      e is PermissionDenied ? l10n.eventRsvpRefused : l10n.eventRsvpFailed,
    );
  }
}

/// Going, Maybe, Not going, and No response, each with its people and
/// notes; players show who answered for them (PLAYER-6).
class _AttendeeGroups extends StatelessWidget {
  const new({
    required this.people,
    required this.rsvps,
    required this.allowMaybe,
    required this.nameOf,
    this.onTap,
  });

  final List<Participant> people;
  final List<Rsvp> rsvps;
  final bool allowMaybe;
  final String Function(String uid) nameOf;

  /// Admins: what tapping this person does (set their answer, SCHED-4),
  /// or null when their row isn't tappable.
  final VoidCallback? Function(Participant)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final byStatus = <RsvpStatus?, List<(Participant, Rsvp?)>>{};
    for (final p in people) {
      final r = answerOf(rsvps, p.id);
      (byStatus[r?.status] ??= []).add((p, r));
    }
    final groups = [
      RsvpStatus.going,
      if (allowMaybe || (byStatus[RsvpStatus.maybe]?.isNotEmpty ?? false))
        RsvpStatus.maybe,
      RsvpStatus.notGoing,
      null,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in groups)
          if (byStatus[s] case final list? when list.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, Space.md, gutter, 0),
              child: Text(
                '${s == null ? l10n.rsvpNoResponse : statusLabel(l10n, s)}'
                ' · ${list.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: s == null
                      ? scheme.onSurfaceVariant
                      : statusColor(context, s),
                ),
              ),
            ),
            for (final (p, r) in list)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: gutter),
                leading: Icon(
                  s == null ? AppIcons.rsvp : statusIcon(s),
                  color: s == null ? scheme.outline : statusColor(context, s),
                ),
                title: Text(p.shownName),
                subtitle: _subtitle(l10n, p, r),
                onTap: onTap?.call(p),
              ),
          ],
      ],
    );
  }

  Widget? _subtitle(AppLocalizations l10n, Participant p, Rsvp? r) {
    if (r == null) return null;
    final parts = [
      if (r.note.isNotEmpty) '"${r.note}"',
      if (p.isPlayer && r.respondedBy.isNotEmpty)
        l10n.eventAnsweredBy(nameOf(r.respondedBy))
      else if (!p.isPlayer && r.respondedBy.isNotEmpty && r.respondedBy != p.id)
        l10n.eventAnsweredBy(nameOf(r.respondedBy)),
    ];
    return parts.isEmpty ? null : Text(parts.join(' · '));
  }
}

/// Admins: pick someone, then their answer (SCHED-4).
Future<void> _setRsvpForSomeone(
  BuildContext context,
  WidgetRef ref,
  Event event,
  Group group,
) async {
  final l10n = AppLocalizations.of(context);
  final roster = ref.read(rosterProvider(group.id)).value ?? const [];
  final players = event.forPlayers
      ? ref.read(playersProvider(group.id)).value ?? const []
      : const <Never>[];
  final everyone = eventParticipants(event, roster, players);
  final me = UserId(ref.read(authUserProvider).value?.uid ?? '');
  final picked = await showAdaptiveSheet<Participant>(
    context,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(
            l10n.eventSetRsvpFor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final p in [...everyone.main, ...everyone.staff])
          if (canSetRsvpFor(event, p, me))
            ListTile(
              title: Text(p.shownName),
              onTap: () => Navigator.of(context).pop(p),
            ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  await _setRsvpFor(context, ref, event, group, picked);
}

/// Admins: choose [p]'s answer.
Future<void> _setRsvpFor(
  BuildContext context,
  WidgetRef ref,
  Event event,
  Group group,
  Participant p,
) async {
  final l10n = AppLocalizations.of(context);
  final status = await showAdaptiveSheet<RsvpStatus>(
    context,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(
            l10n.eventRsvpForPerson(p.shownName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final s in [
          RsvpStatus.going,
          if (group.settings.allowMaybe) RsvpStatus.maybe,
          RsvpStatus.notGoing,
        ])
          ListTile(
            leading: Icon(statusIcon(s), color: statusColor(context, s)),
            title: Text(statusLabel(l10n, s)),
            onTap: () => Navigator.of(context).pop(s),
          ),
      ],
    ),
  );
  if (status == null || !context.mounted) return;
  final rsvps =
      ref.read(eventRsvpsProvider(group.id, event.id)).value ?? const [];
  await setRsvpWithFeedback(
    context,
    ref,
    event,
    RsvpAnswer(
      participant: p,
      status: status,
      note: answerOf(rsvps, p.id)?.note ?? '',
    ),
  );
}

/// The optional note on an answer ("Leaving at halftime", SCHED-4).
class _NoteDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.eventNoteTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: Limits.rsvpNoteMax,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.eventNoteHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
