import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
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
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/event_actions.dart';
import 'package:battleplan/features/schedule/presentation/event_assignments.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// An event's page (SCHED-4): every field, big Going / Maybe / Not going
/// buttons (one set per player I'm linked to, and Me, PLAYER-6), who's
/// coming,
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
    final canCreate = canCreateEvents(group, me, superAdmin: superAdmin);

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
        case _Action.repost:
          await _repostToChat(context, ref, event);
        case _Action.emailRsvp:
          await _emailRsvpReminder(context, ref, event);
      }
    }

    final icon = headerIconStyle(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 62,
        // The round lemon back button (design §3.2).
        leading: (ModalRoute.of(context)?.impliesAppBarDismissal ?? false)
            ? const LemonBackButton()
            : null,
        actionsPadding: const EdgeInsetsDirectional.only(end: 10),
        actions: [
          IconButton(
            style: icon,
            tooltip: l10n.eventAddToCalendar,
            icon: const Icon(AppIcons.addToCalendar),
            onPressed: () => unawaited(addToCalendar(context, ref, event)),
          ),
          IconButton(
            style: icon,
            tooltip: l10n.share,
            icon: const Icon(AppIcons.share),
            onPressed: () => unawaited(shareEvent(context, ref, event)),
          ),
          if (canManage || canCreate)
            PopupMenuButton<_Action>(
              style: icon,
              icon: const Icon(AppIcons.menu),
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
                // Team admins and super admins answer for anyone (§3).
                if (canManage &&
                    event.takesRsvps &&
                    (superAdmin || (me?.isAdmin ?? false)))
                  PopupMenuItem(
                    value: _Action.setRsvp,
                    child: Text(l10n.eventSetRsvpFor),
                  ),
                // A reminder by hand, in the chat (SCHED-8).
                if (canRepost(event, group, me, superAdmin: superAdmin))
                  PopupMenuItem(
                    value: _Action.repost,
                    child: Text(l10n.eventRepost),
                  ),
                // RSVPs by email for whoever hasn't answered (SCHED-14).
                if (canEmailRsvpReminder(
                  event,
                  group,
                  me,
                  superAdmin: superAdmin,
                ))
                  PopupMenuItem(
                    value: _Action.emailRsvp,
                    child: Text(l10n.eventEmailRsvp),
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

enum _Action { edit, duplicate, setRsvp, repost, emailRsvp, cancel, delete }

/// Emails the people linked to players who haven't RSVP'd, after asking
/// how many it will be (SCHED-14). They answer from the email.
Future<void> _emailRsvpReminder(
  BuildContext context,
  WidgetRef ref,
  Event event,
) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(eventRepositoryProvider);
  void say(String text) {
    if (context.mounted) showAppSnackBar(context, text);
  }

  String failure(AppFailure e) => switch (e) {
    RateLimited() => l10n.eventEmailRsvpTooSoon,
    PermissionDenied() => l10n.notAllowed,
    _ => l10n.eventEmailRsvpFailed,
  };
  try {
    final count = await repo.emailRsvpReminder(event.id, dryRun: true);
    if (!context.mounted) return;
    if (count.people == 0) {
      return say(
        count.unreachable > 0
            ? l10n.eventEmailRsvpNobody
            : l10n.eventEmailRsvpEveryone,
      );
    }
    final ok = await showConfirmDialog(
      context,
      title: l10n.eventEmailRsvpTitle(count.people),
      message: l10n.eventEmailRsvpBody,
      confirmLabel: l10n.eventEmailRsvpConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !context.mounted) return;
    final sent = await repo.emailRsvpReminder(event.id);
    final emailed = sent.people - sent.failed;
    say(
      emailed > 0
          ? l10n.eventEmailRsvpSent(emailed)
          : sent.people == 0
          ? l10n.eventEmailRsvpEveryone
          : l10n.eventEmailRsvpFailed,
    );
  } on AppFailure catch (e) {
    say(failure(e));
  }
}

/// Posts [event] in the chat again as a reminder, after asking (SCHED-8).
Future<void> _repostToChat(
  BuildContext context,
  WidgetRef ref,
  Event event,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l10n.eventRepostTitle,
    message: l10n.eventRepostBody,
    confirmLabel: l10n.eventRepostConfirm,
    cancelLabel: l10n.cancel,
  );
  if (!ok || !context.mounted) return;
  try {
    await ref.read(eventRepositoryProvider).repostToChat(event.id);
    if (context.mounted) showAppSnackBar(context, l10n.eventReposted);
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(context, switch (e) {
      RateLimited() => l10n.eventRepostTooSoon,
      PermissionDenied() => l10n.notAllowed,
      _ => l10n.eventRepostFailed,
    });
  }
}

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
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final series = event.seriesId == null
        ? null
        : ref.watch(eventSeriesProvider(event.seriesId!)).value;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.lg, gutter, Space.xxl),
      children: [
        _GameCard(event: event, zone: zone, series: series),
        if (event.location != null || event.reminderOffsets.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          // Directions, and when the reminders go (design §3.5).
          Wrap(
            spacing: 10,
            runSpacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (event.location case final loc?)
                OutlinedButton.icon(
                  style: GumdropButtons.of(context).secondary(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontSize: 15),
                  ),
                  onPressed: () => unawaited(openDirections(ref, loc)),
                  icon: const Icon(AppIcons.directions, size: 18),
                  label: Text(l10n.eventDirections),
                ),
              if (event.reminderOffsets.isNotEmpty)
                InfoPill(
                  icon: AppIcons.reminder,
                  text: l10n.eventRemindersLine(
                    joinAnd(l10n, [
                      for (final o in event.reminderOffsets)
                        reminderLabel(l10n, o),
                    ]),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.md),
        _RsvpSection(event: event, group: group, me: me),
        // Snacks, drinks, a scorekeeper (SCHED-15): secondary, so last.
        const SizedBox(height: Space.lg),
        AssignmentsRow(event: event, group: group, me: me),
      ],
    );
  }
}

/// The event's hero card (design §3.5): the type's candy with ink on it,
/// the type and how soon, the opponent's letter, the title, and every
/// detail under a dashed line.
class _GameCard extends StatelessWidget {
  const new({required this.event, required this.zone, required this.series});

  final Event event;
  final String zone;
  final EventSeries? series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final accent = typeAccent(context, event.type);
    final ink = c.ink;
    final detail = theme.textTheme.bodyLarge?.copyWith(
      color: ink,
      fontWeight: FontWeight.w800,
    );
    final small = theme.textTheme.bodyMedium?.copyWith(
      color: ink,
      fontWeight: FontWeight.w700,
    );
    final chip = theme.textTheme.labelMedium?.copyWith(
      fontSize: 13,
      letterSpacing: 13 * 0.07,
      height: 1,
    );
    final otherZone = otherZoneLine(l10n, event, zone);
    final start = ZonedTime.wallClock(zone, event.startAt);
    final opponent = event.isGame ? event.opponent?.trim() ?? '' : '';
    final soon = _soonLabel(l10n, start);
    final subtitle = [
      if (event.isGame && event.homeAway == HomeAway.home) l10n.eventHome,
      if (event.isGame && event.homeAway == HomeAway.away) l10n.eventAway,
      if (!event.allDay) dayLabel(l10n, start),
    ].join(' · ');

    Widget line(IconData icon, Widget child) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 19, color: ink, weight: 600),
        ),
        const SizedBox(width: 9),
        Expanded(child: child),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
      decoration: GumdropStyle.of(context)
          .cardDecoration(accent.face, Corners.sheet),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: ink),
        child: IconTheme.merge(
          data: IconThemeData(color: ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  _HeroChip(
                    background: ink,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeIcon(event.type),
                          size: 14,
                          color: accent.face,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          typeLabel(l10n, event.type).toUpperCase(),
                          style: chip?.copyWith(color: accent.face),
                        ),
                      ],
                    ),
                  ),
                  if (soon != null && !event.isCanceled)
                    _HeroChip(
                      background: GumdropColors.inkTint14,
                      child: Text(
                        soon.toUpperCase(),
                        style: chip?.copyWith(color: ink),
                      ),
                    ),
                  if (event.isCanceled) const CanceledBadge(),
                ],
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  if (opponent.isNotEmpty) ...[
                    ExcludeSemantics(
                      child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          opponent.characters.first.toUpperCase(),
                          textScaler: TextScaler.noScaling,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 29,
                            height: 1,
                            color: accent.face,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 38,
                            height: 1,
                            color: ink,
                            shadows: const [],
                            decoration: event.isCanceled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: ink,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(subtitle, style: detail),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              CustomPaint(
                painter: const _DashedLine(color: GumdropColors.inkTint30),
                child: Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(
                        AppIcons.time,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeRange(
                                l10n,
                                event,
                                zone,
                                withDay: event.allDay,
                              ),
                              style: detail,
                            ),
                            if (otherZone != null)
                              Text(otherZone, style: small),
                            if (event.isGame &&
                                event.arriveMinutesBefore != null)
                              Text(
                                l10n.eventArrive(event.arriveMinutesBefore!),
                                style: small,
                              ),
                          ],
                        ),
                      ),
                      if (series != null) ...[
                        const SizedBox(height: 6),
                        line(
                          AppIcons.repeat,
                          Text(
                            repeatsLine(l10n, series!.recurrence),
                            style: detail,
                          ),
                        ),
                      ],
                      // The opponent, when the title doesn't already say.
                      if (opponent.isNotEmpty &&
                          !event.title.contains(opponent)) ...[
                        const SizedBox(height: 6),
                        line(
                          AppIcons.game,
                          Text(l10n.eventOpponentLine(opponent), style: detail),
                        ),
                      ],
                      if (event.location case final loc?) ...[
                        const SizedBox(height: 6),
                        line(
                          AppIcons.location,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (loc.name.isNotEmpty)
                                Text(loc.name, style: detail),
                              if (loc.address.isNotEmpty)
                                Text(loc.address, style: small),
                            ],
                          ),
                        ),
                      ],
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        line(
                          AppIcons.notes,
                          SelectableText(event.description, style: small),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Today", "Tomorrow", "In 3 days" for an event in the next two weeks.
  static String? _soonLabel(AppLocalizations l10n, DateTime start) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final day = DateTime.utc(start.year, start.month, start.day);
    final days = day.difference(today).inDays;
    if (days < 0 || days > 14) return null;
    return l10n.eventInDays(days);
  }
}

/// A 25 px chip on the hero card (design §3.5).
class _HeroChip extends StatelessWidget {
  const new({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 25),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: child,
  );
}

/// The hero card's 2 px dashed rule along the top of its details.
class _DashedLine extends CustomPainter {
  const new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 6.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 1),
        Offset((x + dash).clamp(0, size.width), 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.color != color;
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
    final c = GumdropColors.of(context);
    // Text straight on the page (Candy's differs from its cards').
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: c.textMutedOnPage,
      fontWeight: FontWeight.w800,
    );
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
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
    final players = ref.watch(playersProvider(group.id)).value ?? const [];
    final links = ref.watch(guardianLinksProvider(group.id)).value ?? const [];
    final viewer = me;
    final answering = ref.watch(myParticipantsProvider(group.id));
    final mine = viewer == null
        ? answering
        : withOwnAnswer(answering, viewer, rsvps);
    final open = canAnswerNow(event, group, me, now);
    // Super admins answer for anyone too, on any team (§3).
    final isAdmin =
        (me?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final allowMaybe = group.settings.allowMaybe;
    final everyone = eventParticipants(
      roster,
      players,
      links: links,
      rsvps: rsvps,
    );

    // Admins set anyone's answer (SCHED-4).
    final canSet = isAdmin && event.takesRsvps && !group.isArchived;
    VoidCallback? setFor(Participant p) => canSet
        ? () => unawaited(_setRsvpFor(context, ref, event, group, p))
        : null;

    String nameOf(String uid) =>
        roster.where((m) => m.uid.value == uid).firstOrNull?.shortName ??
        l10n.formerMember;

    // The count tiles (design §3.16): the main group's answers.
    final counted = everyone.main.isNotEmpty ? everyone.main : everyone.staff;
    final tally = <RsvpStatus?, int>{};
    for (final p in counted) {
      final s = answerOf(rsvps, p.id)?.status;
      tally[s] = (tally[s] ?? 0) + 1;
    }
    final asking = !event.isCanceled && mine.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: Space.xs),
          child: Text(
            asking ? l10n.eventAreYouGoing : l10n.eventRsvpTitle,
            style: theme.textTheme.headlineSmall,
          ),
        ),
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
        // Canceled events take no answers (SCHED-7). Two or more players
        // get one answer for all of them first (PLAYER-11).
        if (!event.isCanceled && mine.where((p) => p.isPlayer).length > 1)
          padded(
            SameAnswerButtons(
              event: event,
              players: [
                for (final p in mine)
                  if (p.isPlayer) p,
              ],
              answerOf: (id) => answerOf(rsvps, id),
              enabled: open,
              allowMaybe: allowMaybe,
            ),
          ),
        if (!event.isCanceled)
          for (final p in mine)
            padded(
              RsvpButtons(
                event: event,
                participant: p,
                answer: answerOf(rsvps, p.id),
                label: rsvpRowLabel(l10n, p, mine.length),
                enabled: open,
                allowMaybe: allowMaybe,
              ),
            ),
        if (counted.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in [
                RsvpStatus.going,
                if (allowMaybe || (tally[RsvpStatus.maybe] ?? 0) > 0)
                  RsvpStatus.maybe,
                RsvpStatus.notGoing,
                null,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: Space.sm),
                Expanded(
                  child: StatTile(
                    count: tally[s] ?? 0,
                    label: s == null
                        ? l10n.rsvpNoResponse
                        : statusLabel(l10n, s),
                    color: (card) =>
                        s == null ? null : statusAccent(card, s).text,
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: Space.md),
        Text(
          eventCountsText(
            l10n,
            event,
            players: players.length,
            allowMaybe: allowMaybe,
          ),
          style: muted,
        ),
        _AttendeeGroups(
          people: everyone.main,
          rsvps: rsvps,
          allowMaybe: allowMaybe,
          nameOf: nameOf,
          onTap: setFor,
        ),
        // Everyone answering for themselves, apart from the players (Q14).
        // A team without players lists them on their own.
        if (everyone.staff.isNotEmpty) ...[
          if (everyone.main.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.lg),
              child: Text(l10n.eventOthers, style: theme.textTheme.titleLarge),
            ),
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
/// note ("Leaving at halftime") and Clear, back to "No response" (SCHED-5).
/// Tapping the chosen answer again keeps it, or with [clearOnRepeat] (the
/// schedule list) clears it.
class RsvpButtons extends ConsumerWidget {
  const new({
    required this.event,
    required this.participant,
    required this.answer,
    required this.enabled,
    this.label,
    this.allowMaybe = true,
    this.compact = false,
    this.clearOnRepeat = false,
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

  /// A tap on the chosen answer clears it, back to "No response".
  final bool clearOnRepeat;

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
        RsvpChoice(
          statuses: statuses,
          current: current,
          compact: compact,
          onChanged: enabled
              ? (s) {
                  Haptics.selection();
                  unawaited(_answer(context, ref, s, answer?.note ?? ''));
                }
              : null,
          onCleared: enabled && clearOnRepeat
              ? () => unawaited(
                  clearRsvpWithFeedback(context, ref, event, participant),
                )
              : null,
        ),
        if (!compact &&
            ((answer?.note.isNotEmpty ?? false) ||
                (enabled && current != null)))
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Row(
              children: [
                Expanded(
                  child: (answer?.note.isNotEmpty ?? false)
                      ? Text(
                          answer!.note,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: GumdropColors.of(context).textMutedOnPage,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Clear and the note, wrapping under each other when the
                // text is large (SPEC §7.6).
                if (enabled && current != null)
                  Flexible(
                    flex: 2,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Space.sm,
                        children: [
                          TextButton(
                            onPressed: () => unawaited(
                              clearRsvpWithFeedback(
                                context,
                                ref,
                                event,
                                participant,
                              ),
                            ),
                            child: Text(l10n.eventClearAnswer),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                unawaited(_editNote(context, ref, current)),
                            icon: const Icon(AppIcons.edit, size: 16),
                            label: Text(
                              answer?.note.isNotEmpty ?? false
                                  ? l10n.eventEditNote
                                  : l10n.eventAddNote,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
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

/// "All my players" (PLAYER-11): one tap gives every player I answer for
/// the same answer, written in one batch, each keeping its note. It shows
/// that answer while they all have it. My own answer as a member (Me)
/// stays apart.
class SameAnswerButtons extends ConsumerWidget {
  const new({
    required this.event,
    required this.players,
    required this.answerOf,
    required this.enabled,
    this.allowMaybe = true,
    this.compact = false,
    super.key,
  });

  final Event event;

  /// Two or more players I answer for.
  final List<Participant> players;
  final Rsvp? Function(String participantId) answerOf;
  final bool enabled;
  final bool allowMaybe;

  /// The chat card's smaller buttons, without icons, as [RsvpButtons].
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statuses = {for (final p in players) answerOf(p.id)?.status};
    final shared = statuses.length == 1 ? statuses.single : null;
    final options = [
      RsvpStatus.going,
      if (allowMaybe || shared == RsvpStatus.maybe) RsvpStatus.maybe,
      RsvpStatus.notGoing,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: compact ? Space.xs : Space.sm,
            bottom: Space.xs,
          ),
          child: Text(l10n.rsvpAllMyPlayers, style: theme.textTheme.titleSmall),
        ),
        RsvpChoice(
          statuses: options,
          current: shared,
          compact: compact,
          onChanged: enabled
              ? (s) {
                  Haptics.selection();
                  unawaited(_answerAll(context, ref, s));
                }
              : null,
        ),
      ],
    );
  }

  /// Answers every player that doesn't have [status] yet.
  Future<void> _answerAll(
    BuildContext context,
    WidgetRef ref,
    RsvpStatus status,
  ) => setRsvpsWithFeedback(context, ref, event, [
    for (final p in players)
      if (answerOf(p.id)?.status != status)
        RsvpAnswer(
          participant: p,
          status: status,
          note: answerOf(p.id)?.note ?? '',
        ),
  ]);
}

/// Writes an answer and says so if it's refused or fails.
Future<void> setRsvpWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Event event,
  RsvpAnswer answer,
) => setRsvpsWithFeedback(context, ref, event, [answer]);

/// Writes answers together (PLAYER-11) and says so if they're refused or
/// fail: all of them save, or none.
Future<void> setRsvpsWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Event event,
  List<RsvpAnswer> answers,
) async {
  if (answers.isEmpty) return;
  final l10n = AppLocalizations.of(context);
  final uid = ref.read(authUserProvider).value?.uid;
  if (uid == null) return;
  final repo = ref.read(rsvpRepositoryProvider);
  try {
    await (answers.length == 1
        ? repo.setRsvp(event, answers.single, by: UserId(uid))
        : repo.setRsvps(event, answers, by: UserId(uid)));
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      e is PermissionDenied ? l10n.eventRsvpRefused : l10n.eventRsvpFailed,
    );
  }
}

/// Clears [participant]'s answer (SCHED-5) and says so if it's refused or
/// fails.
Future<void> clearRsvpWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Event event,
  Participant participant,
) async {
  final l10n = AppLocalizations.of(context);
  Haptics.selection();
  try {
    await ref.read(rsvpRepositoryProvider).clearRsvp(event, participant);
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
    final c = GumdropColors.of(context);
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
              padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
              child: Row(
                children: [
                  Icon(
                    s == null ? AppIcons.rsvp : statusIcon(s),
                    size: 18,
                    color: s == null
                        ? c.textMutedOnPage
                        : statusColor(context, s),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${s == null ? l10n.rsvpNoResponse : statusLabel(l10n, s)}'
                      ' · ${list.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: s == null
                            ? c.textMutedOnPage
                            : statusColor(context, s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final (i, (p, r)) in list.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : Space.sm),
                child: _AttendeeRow(
                  participant: p,
                  status: s,
                  subtitle: _subtitle(l10n, p, r),
                  onTap: onTap?.call(p),
                ),
              ),
          ],
      ],
    );
  }

  String? _subtitle(AppLocalizations l10n, Participant p, Rsvp? r) {
    if (r == null) return null;
    final parts = [
      if (r.note.isNotEmpty) '"${r.note}"',
      if (p.isPlayer && r.respondedBy.isNotEmpty)
        l10n.eventAnsweredBy(nameOf(r.respondedBy))
      else if (!p.isPlayer && r.respondedBy.isNotEmpty && r.respondedBy != p.id)
        l10n.eventAnsweredBy(nameOf(r.respondedBy)),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// One person on the event (design §3.16): their candy initials, name, who
/// answered or their note, and their answer's disc, on a card. Admins tap
/// it to set the answer (SCHED-4).
class _AttendeeRow extends StatelessWidget {
  const new({
    required this.participant,
    required this.status,
    required this.subtitle,
    required this.onTap,
  });

  final Participant participant;
  final RsvpStatus? status;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: onTap,
      radius: Corners.tile,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final c = GumdropColors.of(context);
          return Row(
            children: [
              CandyInitials(
                name: participant.shownName,
                colorKey: participant.id,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.shownName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.2,
                        color: c.textPrimary,
                      ),
                    ),
                    if (subtitle case final text?)
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // The group heading above says the answer in words.
              AnswerDisc(status: status, size: 28),
            ],
          );
        },
      ),
    );
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
  final players = ref.read(playersProvider(group.id)).value ?? const [];
  // Admins set anyone's answer, members included (SCHED-4).
  final everyone = (
    main: [for (final p in players) playerParticipant(p)],
    staff: [
      for (final m in roster)
        Participant(
          type: ParticipantType.member,
          id: m.uid.value,
          name: m.displayName,
        ),
    ],
  );
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
