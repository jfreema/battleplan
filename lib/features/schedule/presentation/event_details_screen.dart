import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
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
        case _Action.repost:
          await _repostToChat(context, ref, event);
        case _Action.emailRsvp:
          await _emailRsvpReminder(context, ref, event);
      }
    }

    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    IconButton action(String tip, IconData glyph, VoidCallback onTap) =>
        IconButton(
          tooltip: tip,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          iconSize: 24,
          icon: Icon(glyph),
          onPressed: onTap,
        );
    return Scaffold(
      appBar: AppBar(
        // The back row only: the opener's name, or the chevron alone from
        // a notification or a link.
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        excludeHeaderSemantics: true,
        titleSpacing: 4,
        title: canPop
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: BackChevron(
                  label: switch (backLabelFrom(context, '')) {
                    final from? when from.isNotEmpty => from,
                    _ => null,
                  },
                ),
              )
            : null,
        actionsPadding: const EdgeInsetsDirectional.only(end: 4),
        actions: [
          action(
            l10n.eventAddToCalendar,
            AppIcons.addToCalendar,
            () => unawaited(addToCalendar(context, ref, event)),
          ),
          action(
            l10n.share,
            AppIcons.share,
            () => unawaited(shareEvent(context, ref, event)),
          ),
          if (canManage || canCreate)
            PopupMenuButton<_Action>(
              iconSize: 24,
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

enum _Action { edit, duplicate, repost, emailRsvp, cancel, delete }

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
    RateLimited(message: 'emailed-this-week') => l10n.eventEmailRsvpThisWeek,
    RateLimited() => l10n.eventEmailRsvpLimit,
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
      message: [
        l10n.eventEmailRsvpBody,
        // Today's limits can leave some for another day (SCHED-14).
        if (count.skipped > 0) l10n.eventEmailRsvpRest(count.skipped),
      ].join(' '),
      confirmLabel: l10n.eventEmailRsvpConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !context.mounted) return;
    final sent = await repo.emailRsvpReminder(event.id);
    final emailed = sent.people - sent.failed;
    say(
      emailed > 0
          ? [
              l10n.eventEmailRsvpSent(emailed),
              if (sent.skipped > 0) l10n.eventEmailRsvpRest(sent.skipped),
            ].join(' ')
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
    final c = GumdropColors.of(context);
    final series = event.seriesId == null
        ? null
        : ref.watch(eventSeriesProvider(event.seriesId!)).value;

    // When the reminders go: an all-day event's as the days before, at 6 PM.
    final reminders = event.allDay
        ? allDayReminders(event.reminderOffsets)
        : event.reminderOffsets;
    final otherZone = otherZoneLine(l10n, event, zone);
    final opponent = event.isGame ? event.opponent?.trim() ?? '' : '';
    final arrive = event.isGame && event.arriveMinutesBefore != null
        ? l10n.eventArrive(event.arriveMinutesBefore!)
        : null;

    // No fade over the end of the scroll: it dimmed the text under it
    // below 4.5:1.
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _Hero(event: event, zone: zone),
            const SizedBox(height: 8),
            PageRows(
              children: [
                if (otherZone != null || arrive != null)
                  PageRow(
                    icon: AppIcons.time,
                    title: otherZone ?? arrive!,
                    subtitle: otherZone != null ? arrive : null,
                    subtitleMaxLines: null,
                  ),
                if (event.location case final loc?)
                  PageRow(
                    icon: AppIcons.location,
                    title: loc.name.isNotEmpty ? loc.name : loc.address,
                    subtitle: loc.name.isNotEmpty && loc.address.isNotEmpty
                        ? loc.address
                        : null,
                    subtitleMaxLines: null,
                    trailing: TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => unawaited(openDirections(ref, loc)),
                      icon: Icon(
                        AppIcons.directions,
                        size: 18,
                        color: c.accentMark,
                      ),
                      label: Text(l10n.eventDirections),
                    ),
                  ),
                if (series != null)
                  PageRow(
                    icon: AppIcons.repeat,
                    title: repeatsLine(l10n, series.recurrence),
                  ),
                // The opponent, when the title doesn't already say.
                if (opponent.isNotEmpty && !event.title.contains(opponent))
                  PageRow(
                    icon: AppIcons.game,
                    title: l10n.eventOpponentLine(opponent),
                  ),
                if (reminders.isNotEmpty)
                  PageRow(
                    icon: AppIcons.reminder,
                    title: event.allDay
                        ? l10n.eventRemindersAllDayLine(
                            joinAnd(l10n, [
                              for (final o in reminders) reminderLabel(l10n, o),
                            ]),
                          )
                        : l10n.eventRemindersLine(
                            joinAnd(l10n, [
                              for (final o in reminders) reminderLabel(l10n, o),
                            ]),
                          ),
                  ),
                if (event.description.isNotEmpty)
                  SelectionArea(
                    child: PageRow(
                      icon: AppIcons.notes,
                      title: event.description,
                    ),
                  ),
                // Snacks, drinks, a scorekeeper (SCHED-15).
                if (hasAssignmentsRow(ref, event, group, me))
                  AssignmentsRow(event: event, group: group, me: me),
              ],
            ),
            _RsvpSection(event: event, group: group, me: me),
          ],
        ),
      ],
    );
  }
}

/// The top of the event (SPEC §7.3): the stencil eyebrow (the type, and
/// Home or Away) with how soon on the right, the opponent's crest and name
/// in Lilita 48 for a game (else the title in Lilita 32), and when.
class _Hero extends StatelessWidget {
  const new({required this.event, required this.zone});

  final Event event;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context);
    final accent = typeAccent(context, event.type);
    // The type's color on the page (social is the going color).
    final eyebrowColor = event.type == EventType.social
        ? c.successOnPage
        : accent.text;
    final opponent = event.isGame ? event.opponent?.trim() ?? '' : '';
    final soon = _soonLabel(l10n, event, zone);
    final eyebrow = [
      typeLabel(l10n, event.type),
      if (event.isGame && event.homeAway == HomeAway.home) l10n.eventHome,
      if (event.isGame && event.homeAway == HomeAway.away) l10n.eventAway,
    ].join(' · ');
    final strike = event.isCanceled ? TextDecoration.lineThrough : null;
    // The crest and the big name only for a title that's the opponent
    // ("vs. Eagles", "@ Eagles"); any other title is shown whole.
    final match = opponent.isEmpty
        ? null
        : RegExp(r'^\s*(vs\.?|@)?\s*' + RegExp.escape(opponent) + r'\s*$')
              .firstMatch(event.title);
    final crestName = match == null ? null : opponent;
    final prefix = match?.group(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  semanticsLabel: eyebrow,
                  style: TextStyle(
                    fontFamily: AppFonts.sticker,
                    fontSize: 13,
                    height: 16 / 13,
                    letterSpacing: 13 * 0.18,
                    color: eyebrowColor,
                  ),
                ),
              ),
              if (event.isCanceled)
                const CanceledBadge()
              else if (soon != null) ...[
                Icon(AppIcons.time, size: 16, color: c.tangerine.text),
                const SizedBox(width: 5),
                Text(
                  soon,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 20 / 15,
                    color: c.textOnPage,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (crestName != null)
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.tangerine.face,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.tangerine.lip, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: c.tangerine.lip,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    crestName.characters.first.toUpperCase(),
                    textScaler: TextScaler.noScaling,
                    style: style.display(
                      TextStyle(fontSize: 28, height: 1, color: c.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (prefix != null)
                        TextSpan(
                          text: '$prefix ',
                          style: style.label(
                            TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: c.textMutedOnPage,
                              shadows: const [],
                            ),
                          ),
                        ),
                      TextSpan(text: crestName),
                    ],
                  ),
                  semanticsLabel: event.title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 48,
                    height: 50 / 48,
                    decoration: strike,
                  ),
                ),
              ),
            ],
          )
        else
          Semantics(
            header: true,
            child: Text(
              event.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                height: 36 / 32,
                decoration: strike,
              ),
            ),
          ),
        const SizedBox(height: 7),
        Text(
          [
            if (!event.allDay)
              dayLabel(l10n, ZonedTime.wallClock(zone, event.startAt)),
            timeRange(l10n, event, zone, withDay: event.allDay),
          ].join(' · '),
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            height: 22 / 17,
            color: c.textOnPage,
          ),
        ),
      ],
    );
  }

  /// "Today", "Tomorrow", "In 3 days" for an event in the next two weeks,
  /// counted in the viewer's [zone] (SET-7).
  static String? _soonLabel(AppLocalizations l10n, Event event, String zone) {
    final now = ZonedTime.wallClock(zone, DateTime.now());
    final today = DateTime.utc(now.year, now.month, now.day);
    final days = dayOf(event, zone).difference(today).inDays;
    if (days < 0 || days > 14) return null;
    return l10n.eventInDays(days);
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
    final c = GumdropColors.of(context);
    // Text straight on the page (it differs from the cards').
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: c.textMutedOnPage,
      fontWeight: FontWeight.w800,
    );
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: child,
    );

    if (!event.rsvpEnabled) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: padded(Text(l10n.eventRsvpsOff, style: muted)),
      );
    }

    final now = DateTime.now();
    final zone = ref.watch(viewerTimeZoneProvider).value ?? event.timeZone;
    final rsvps =
        ref.watch(eventRsvpsProvider(group.id, event.id)).value ?? const [];
    final roster = ref.watch(rosterProvider(group.id)).value ?? const [];
    // On a team only players have answers; in a group, which has no
    // players, everyone answers for themselves (PLAYER-6, TEAM-14).
    final isTeam = group.hasPlayers;
    final playersAsync = isTeam ? ref.watch(playersProvider(group.id)) : null;
    final linksAsync = isTeam
        ? ref.watch(guardianLinksProvider(group.id))
        : null;
    // Until a team's players and links are in, who I answer for and
    // whether it has players aren't known: nothing shows yet, so no empty
    // state flashes by (an admin's Add players, a guardian's "only
    // players").
    if (isTeam && !(playersAsync!.hasValue && linksAsync!.hasValue)) {
      return const SizedBox.shrink();
    }
    final players = playersAsync?.value ?? const <Player>[];
    final links = linksAsync?.value ?? const <GuardianLink>[];
    final mine = ref.watch(myParticipantsProvider(group.id));
    final open = canAnswerNow(event, group, me, now);
    // Super admins answer for anyone too, on any team (§3).
    final isAdmin =
        (me?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final allowMaybe = group.settings.allowMaybe;
    final everyone = eventParticipants(roster, players, isTeam: isTeam);
    final activePlayers = everyone.main.length;
    // Someone on a team with nobody to answer for, as the roster's "Who
    // are you here for?" row tests it: told their claim waits, or, once
    // their claims are in and there are players, pointed to "Who are you
    // here for?" (PLAYER-3, spec 6.3).
    final myUid = ref.watch(authUserProvider).value?.uid;
    final linked = links.any((l) => l.uid.value == myUid);
    final unlinked =
        isTeam && !isAdmin && me != null && !linked && mine.isEmpty;
    final myPending = unlinked
        ? ref.watch(myPendingPlayersProvider(group.id))
        : null;
    final myRequests = unlinked
        ? ref.watch(myGuardianRequestsProvider(group.id))
        : null;
    final waiting =
        unlinked &&
        ((myPending!.value ?? const <Player>[]).any(
              (p) => p.proposedBy == myUid,
            ) ||
            (myRequests!.value ?? const <GuardianRequest>[]).any(
              (r) => r.status == GuardianRequestStatus.pending,
            ));
    final pointToWho =
        unlinked &&
        !waiting &&
        myPending!.hasValue &&
        myRequests!.hasValue &&
        activePlayers > 0 &&
        !event.isCanceled;
    // A team with no players takes no answers yet: its admins are told how
    // to start, unless it's archived (PLAYER-6). Others see no section,
    // unless their claim waits (spec 6.3).
    final noPlayers = isTeam && activePlayers == 0;
    if (noPlayers && !isAdmin && !waiting) return const SizedBox.shrink();
    final addPlayers =
        noPlayers && isAdmin && !group.isArchived && !event.isCanceled;

    // Admins set anyone's answer (SCHED-4).
    final canSet =
        isAdmin &&
        event.takesRsvps &&
        !group.isArchived &&
        (!isTeam || activePlayers > 0);
    VoidCallback? setFor(Participant p) => canSet
        ? () => unawaited(_setRsvpFor(context, ref, event, group, p))
        : null;

    Membership? memberOf(String uid) =>
        roster.where((m) => m.uid.value == uid).firstOrNull;
    String nameOf(String uid) => memberOf(uid)?.shortName ?? l10n.formerMember;
    // The member who is [p]: themselves in a group, a player's self link on
    // a team (PLAYER-3).
    String? selfOf(Participant p) =>
        p.isPlayer ? selfLinkOf(PlayerId(p.id), links)?.uid.value : p.id;

    // The count tiles (design §3.16): the players' answers on a team,
    // everyone's in a group.
    final counted = isTeam ? everyone.main : everyone.staff;
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
          // 14 above the heading (SPEC §7.3), only when there's a section.
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: Semantics(
            header: true,
            child: Text(
              asking ? rsvpHeading(l10n, mine) : l10n.eventRsvpTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 25,
                height: 30 / 25,
              ),
            ),
          ),
        ),
        if (addPlayers)
          padded(
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.sm,
              children: [
                Text(l10n.rsvpAddPlayersFirst, style: muted),
                TextButton(
                  onPressed: () =>
                      context.push('/g/${group.id.value}/players/add'),
                  child: Text(l10n.rsvpAddPlayersAction),
                ),
              ],
            ),
          )
        else if (waiting)
          padded(Text(l10n.claimWaiting, style: muted))
        else if (pointToWho)
          padded(
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.sm,
              children: [
                Text(l10n.rsvpPlayersOnly, style: muted),
                TextButton(
                  onPressed: () => context.push('/g/${group.id.value}/who'),
                  child: Text(l10n.whoAreYouHereFor),
                ),
              ],
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
                // One person is named by the heading ("Is Noah going?").
                label: mine.length > 1
                    ? rsvpRowLabel(l10n, p, mine.length)
                    : null,
                enabled: open,
                allowMaybe: allowMaybe,
              ),
            ),
        // Who's going: the counts, then the people by answer; nothing on a
        // team with no players yet.
        if (counted.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(height: 1, color: c.divider),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.eventWhosGoing,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 25,
                        height: 30 / 25,
                      ),
                    ),
                  ),
                ),
                if (canSet)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.5,
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => unawaited(
                        _setRsvpForSomeone(context, ref, event, group),
                      ),
                      icon: const Icon(AppIcons.roster, size: 20),
                      label: Text(
                        isTeam ? l10n.eventRsvpForPlayer : l10n.eventSetRsvpFor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in [
                RsvpStatus.going,
                if (allowMaybe || (tally[RsvpStatus.maybe] ?? 0) > 0)
                  RsvpStatus.maybe,
                RsvpStatus.notGoing,
                null,
              ])
                Expanded(
                  child: _Count(
                    count: tally[s] ?? 0,
                    label: s == null ? l10n.rsvpNoReply : statusLabel(l10n, s),
                    color: switch (s) {
                      RsvpStatus.going => c.successOnPage,
                      RsvpStatus.maybe => c.lemon.text,
                      RsvpStatus.notGoing => c.cherry.text,
                      null => c.textOnPage,
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTeam
                ? l10n.rsvpPlayersGoing(
                    tally[RsvpStatus.going] ?? 0,
                    activePlayers,
                  )
                : l10n.rsvpMembersGoing(
                    tally[RsvpStatus.going] ?? 0,
                    group.memberCount,
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 19 / 14,
              fontWeight: FontWeight.w600,
              color: c.textMutedOnPage,
            ),
          ),
        ],
        // The tiles say the counts; the groups below say who.
        _AttendeeGroups(
          people: counted,
          rsvps: rsvps,
          allowMaybe: allowMaybe,
          nameOf: nameOf,
          selfOf: selfOf,
          // Their picked icon color, from the member who is them (§7.2).
          colorOf: (p) => switch (selfOf(p)) {
            final uid? => memberOf(uid)?.avatarColor,
            null => null,
          },
          onTap: setFor,
        ),
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
    void pick(RsvpStatus s) {
      Haptics.selection();
      unawaited(_answer(context, ref, s, answer?.note ?? ''));
    }

    final onChanged = enabled ? pick : null;
    final onCleared = enabled && clearOnRepeat
        ? () =>
              unawaited(clearRsvpWithFeedback(context, ref, event, participant))
        : null;
    if (compact) {
      return _CardRsvpRow(
        label: label,
        semanticName: participant.shownName,
        unanswered: current == null,
        pills: statuses.length,
        choice: RsvpChoice(
          statuses: statuses,
          current: current,
          compact: true,
          onChanged: onChanged,
          onCleared: onCleared,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
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
        if (!compact && (answer?.note.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(
              '"${answer!.note}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: GumdropColors.of(context).textOnPage,
              ),
            ),
          ),
        // The links row: Add a note on the left, Clear on the right.
        if (!compact && enabled && current != null)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () =>
                        unawaited(_editNote(context, ref, current)),
                    icon: const Icon(AppIcons.edit, size: 18),
                    label: Text(
                      answer?.note.isNotEmpty ?? false
                          ? l10n.eventEditNote
                          : l10n.eventAddNote,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: GumdropColors.of(context).textMutedOnPage,
                  ),
                  onPressed: () => unawaited(
                    clearRsvpWithFeedback(context, ref, event, participant),
                  ),
                  child: Text(l10n.eventClearAnswer),
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
    final note = await showCardDialog<String>(
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
/// One count on the event screen (SPEC §7.3): the number in Lilita 40 in
/// its answer's color, and its label in small capitals under it.
class _Count extends StatelessWidget {
  const new({required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: style.display(
              TextStyle(fontSize: 40, height: 42 / 40, color: color),
            ),
          ),
          Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: style.label(
              TextStyle(
                fontSize: 13,
                height: 16 / 13,
                letterSpacing: 13 * 0.04,
                fontWeight: FontWeight.w600,
                color: c.textMutedOnPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The people by answer (SPEC §7.3): a small label for each answer with
/// its dot ("GOING · 10"), then a row per person with a hairline above.
class _AttendeeGroups extends StatelessWidget {
  const new({
    required this.people,
    required this.rsvps,
    required this.allowMaybe,
    required this.nameOf,
    required this.selfOf,
    required this.colorOf,
    this.onTap,
  });

  final List<Participant> people;
  final List<Rsvp> rsvps;
  final bool allowMaybe;
  final String Function(String uid) nameOf;

  /// The uid of the member who is this person, if any.
  final String? Function(Participant) selfOf;

  /// This person's picked icon color, if any.
  final AvatarColor? Function(Participant) colorOf;

  /// Admins: what tapping this person does (set their answer, SCHED-4),
  /// or null when their row isn't tappable.
  final VoidCallback? Function(Participant)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in groups)
          if (byStatus[s] case final list? when list.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s == null
                          ? c.textMutedOnPage
                          : statusAccent(context, s).face,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    // "No reply", as the count above it says.
                    child: SectionLabel(
                      '${s == null ? l10n.rsvpNoReply : statusLabel(l10n, s)}'
                      ' · ${list.length}',
                    ),
                  ),
                ],
              ),
            ),
            for (final (p, r) in list) ...[
              Container(height: 1, color: c.divider),
              _AttendeeRow(
                participant: p,
                rsvp: r,
                color: colorOf(p),
                answeredBy: _answeredBy(l10n, p, r),
                onTap: onTap?.call(p),
              ),
            ],
          ],
      ],
    );
  }

  /// "Answered by Tasha R.", unless they answered for themselves: a member
  /// in a group, or an adult player through their self link (PLAYER-6).
  String? _answeredBy(AppLocalizations l10n, Participant p, Rsvp? r) {
    if (r == null || r.respondedBy.isEmpty) return null;
    if (r.respondedBy == selfOf(p)) return null;
    return l10n.eventAnsweredBy(nameOf(r.respondedBy));
  }
}

/// One person on the event (SPEC §7.3): their icon, name and number, a
/// note in quotes, who answered, and the answer's mark on the right.
/// Admins tap it to set the answer (SCHED-4).
class _AttendeeRow extends StatelessWidget {
  const new({
    required this.participant,
    required this.rsvp,
    required this.answeredBy,
    required this.onTap,
    this.color,
  });

  final Participant participant;
  final Rsvp? rsvp;
  final String? answeredBy;
  final VoidCallback? onTap;

  /// Their picked icon color; null keeps the one picked from their ID.
  final AvatarColor? color;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final s = rsvp?.status;
    final note = rsvp?.note ?? '';
    final full = participant.shownName;
    final hash = full.lastIndexOf(' #');
    final name = hash > 0 ? full.substring(0, hash) : full;
    final number = hash > 0 ? full.substring(hash) : '';
    TextStyle body(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: AppFonts.body,
      fontSize: size,
      height: (size + 5) / size,
      fontWeight: weight,
      color: color,
    );
    return FocusRingInk(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            CandyInitials(name: full, colorKey: participant.id, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: name),
                        if (number.isNotEmpty)
                          TextSpan(
                            text: number,
                            style: body(16, FontWeight.w700, c.textMutedOnPage),
                          ),
                      ],
                    ),
                    style: body(16, FontWeight.w800, c.textOnPage),
                  ),
                  if (note.isNotEmpty)
                    Text(
                      '"$note"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: body(15, FontWeight.w600, c.textOnPage),
                    ),
                  if (answeredBy case final by?)
                    Text(
                      by,
                      style: body(14, FontWeight.w600, c.textMutedOnPage),
                    ),
                ],
              ),
            ),
            if (s != null) ...[
              const SizedBox(width: 12),
              Icon(
                statusIcon(s),
                size: 22,
                weight: 700,
                color: switch (s) {
                  RsvpStatus.going => c.successOnPage,
                  RsvpStatus.maybe => c.lemon.text,
                  RsvpStatus.notGoing => c.notGoingIcon,
                },
              ),
            ],
          ],
        ),
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
  final players = group.hasPlayers
      ? ref.read(playersProvider(group.id)).value ?? const <Player>[]
      : const <Player>[];
  // Admins set a player's answer on a team, anyone's in a group (SCHED-4,
  // PLAYER-6).
  final isTeam = group.hasPlayers;
  final everyone = eventParticipants(roster, players, isTeam: isTeam);
  final picked = await showAdaptiveSheet<Participant>(
    context,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(
            isTeam ? l10n.eventRsvpForPlayer : l10n.eventSetRsvpFor,
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

/// An RSVP row on a card (SPEC §7.3): the name ([label], "Luke" or "You")
/// in a column at least 46 wide, with a coral dot while it's unanswered,
/// then the [pills] (three, or two without Maybe). When the name needs more
/// than 64 px, or a pill would be narrower than 84 px, the name takes its
/// own line above.
class _CardRsvpRow extends StatelessWidget {
  const new({
    required this.label,
    required this.semanticName,
    required this.unanswered,
    required this.pills,
    required this.choice,
  });

  final String? label;
  final String semanticName;
  final bool unanswered;
  final int pills;
  final Widget choice;

  /// The room between a card's pills, as [RsvpChoice] leaves it.
  static const double _pillGap = 4;

  @override
  Widget build(BuildContext context) {
    final text = label;
    if (text == null) return choice;
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context).label(
      TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.2,
        color: c.textMuted,
      ),
    );
    final name = Semantics(
      label: semanticName,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(text, style: style, maxLines: 1),
          ),
          if (unanswered)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.cherry.face,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final nameWidth = painter.width + 8;
        painter.dispose();
        final column = nameWidth < 46 ? 46.0 : nameWidth;
        // Each pill's width beside the name: the rest of the row, less the
        // gaps between the pills, shared.
        final pill =
            (constraints.maxWidth - column - 4 - _pillGap * (pills - 1)) /
            pills;
        final narrow = column > 64 || pill < 84;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 20),
                  child: name,
                ),
              ),
              choice,
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: column, child: name),
            const SizedBox(width: 4),
            Expanded(child: choice),
          ],
        );
      },
    );
  }
}
