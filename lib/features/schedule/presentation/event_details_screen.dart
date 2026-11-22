import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/camp_app_bar.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/dog_tag.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/whole_words.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/players.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_repository.dart';
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
        appBar: const CampAppBar(),
        body: async.isLoading || group == null || zone == null
            ? const SkeletonList()
            // An event that couldn't be read (#40), not one that's gone.
            : async.hasError
            ? LoadError(onRetry: () => ref.invalidate(eventProvider(eventId)))
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
      appBar: CampAppBar(
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
                // The risky ones apart, under a line, in the warning red
                // (#35); both still ask first.
                if (canManage) const PopupMenuDivider(),
                if (canManage && !event.isCanceled)
                  PopupMenuItem(
                    value: _Action.cancel,
                    child: _Danger(l10n.eventCancel),
                  ),
                if (canManage)
                  PopupMenuItem(
                    value: _Action.delete,
                    child: _Danger(l10n.eventDelete),
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
    // None once it's over: they've all gone, or never will (#35).
    final reminders = event.endedBefore(DateTime.now())
        ? const <int>[]
        : event.allDay
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
                    // A blue push button (#85).
                    trailing: FilledButton.icon(
                      style: GumdropButtons.of(context).accent(
                        c.blueRaspberry,
                        height: 42,
                        padding: const EdgeInsets.fromLTRB(9, 0, 10, 0),
                      ),
                      onPressed: () => unawaited(openDirections(ref, loc)),
                      icon: const Icon(AppIcons.directions, size: 18),
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

/// The top of the event (SPEC §7.3; Boot Camp Mix, #85): the kind on a
/// mustard tag ("GAME · HOME") with how soon on a starburst at the right,
/// the opponent's initial on a round red badge beside the title in white
/// stencil in a thick ink outline, turned a little (or the title alone),
/// and when, in an ink-outlined box. A long word steps the size down, so no
/// word ever breaks in two (#74).
class _Hero extends StatelessWidget {
  const new({required this.event, required this.zone});

  final Event event;
  final String zone;

  /// The title's sizes, largest first (#74: no word broken in two).
  static const titleSizes = [51.0, 44.0, 38.0, 32.0, 27.0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final opponent = event.isGame ? event.opponent?.trim() ?? '' : '';
    final soon = _soonLabel(l10n, event, zone);
    final eyebrow = eventKindLabel(l10n, event);
    final strike = event.isCanceled ? TextDecoration.lineThrough : null;
    // The crest only for a title that's the opponent ("vs. Eagles",
    // "@ Eagles"); any other title is shown alone.
    final match = opponent.isEmpty
        ? null
        : RegExp(r'^\s*(vs\.?|@)?\s*' + RegExp.escape(opponent) + r'\s*$')
              .firstMatch(event.title);
    final crestName = match == null ? null : opponent;
    // "vs." or "@" kept on the line of the name's first word by a no-break
    // space (#74).
    final shown = match?.group(1) == null
        ? event.title
        : event.title.replaceFirst(
            RegExp(r'^(\s*(?:vs\.?|@))\s+'),
            '${match!.group(1)}\u00A0',
          );
    final stencil = TextStyle(
      fontFamily: AppFonts.stencil,
      fontWeight: FontWeight.w900,
      color: c.ink,
    );
    final title = LayoutBuilder(
      builder: (context, box) {
        TextStyle titleAt(double size) => stencil.copyWith(
          fontSize: size,
          height: (size + 3) / size,
          letterSpacing: size * 0.025,
          decoration: strike,
          decorationColor: c.ink,
          decorationThickness: 2,
        );
        final size = wholeWordSize(
          context,
          // Room for the outline and the turn.
          maxWidth: box.maxWidth - 8,
          sizes: titleSizes,
          words: (size) => [
            for (final word in shown.split(' '))
              if (word.isNotEmpty) TextSpan(text: word, style: titleAt(size)),
          ],
        );
        return Transform.rotate(
          angle: -2 * 3.141592653589793 / 180,
          alignment: const Alignment(-1, 0.4),
          child: OutlinedText(
            shown,
            semanticsLabel: event.title,
            header: true,
            stroke: size * 0.12,
            shadow: size >= 38 ? 4 : 3,
            style: titleAt(size),
          ),
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 49),
          child: Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 3, top: 4),
                  child: CampTag(eyebrow, size: 13.5),
                ),
              ),
              const Spacer(),
              if (event.isCanceled)
                const CanceledBadge()
              else if (event.endedBefore(DateTime.now()))
                const _EndedBadge()
              else if (soon != null)
                Starburst(
                  width: 104,
                  height: 47,
                  turn: 7,
                  child: Text(
                    '${soon.toUpperCase()}!',
                    semanticsLabel: soon,
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: stencil.copyWith(
                      fontSize: 14.5,
                      height: 1,
                      letterSpacing: 14.5 * 0.05,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        if (crestName != null)
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.tangerine.face,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.ink, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: c.pageShadow,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    crestName.characters.first.toUpperCase(),
                    textScaler: TextScaler.noScaling,
                    style: stencil.copyWith(
                      fontSize: 28,
                      height: 1,
                      color: c.inkOn(c.tangerine),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(child: title),
            ],
          )
        else
          title,
        const SizedBox(height: 7),
        // When, in an ink-outlined box, turned a little.
        Transform.rotate(
          angle: -1.2 * 3.141592653589793 / 180,
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 5, 11, 2),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.ink, width: 3),
              boxShadow: [
                BoxShadow(color: c.pageShadow, offset: const Offset(3, 3)),
              ],
            ),
            child: Text(
              [
                if (!event.allDay)
                  dayLabel(l10n, ZonedTime.wallClock(zone, event.startAt)),
                timeRange(l10n, event, zone, withDay: event.allDay),
              ].join(' · '),
              style: stencil.copyWith(
                fontSize: 17.5,
                height: 24 / 17.5,
                letterSpacing: 17.5 * 0.05,
                color: c.card.textPrimary,
              ),
            ),
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

/// A menu item's words in the warning red (§7.2), as the menu draws it.
class _Danger extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: GumdropColors.of(context).cherry.text),
  );
}

/// "Ended" on the page of an event that's over (SCHED-4, #35): a quiet
/// pill in the well's color, so a past event never passes for an upcoming
/// one. Canceled wins over it.
class _EndedBadge extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.well,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: c.outline),
      ),
      child: Text(
        AppLocalizations.of(context).eventEnded,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: c.textOnPage, letterSpacing: 0.4),
      ),
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
    // players"). A stream that fails falls back to no players or links, so
    // the section still shows.
    bool loading(AsyncValue<Object?>? v) =>
        v != null && v.isLoading && !v.hasValue && !v.hasError;
    if (loading(playersAsync) || loading(linksAsync)) {
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
    // Someone on a team with nobody to answer for, as every "Who are you
    // here for?" prompt tests it ([myPlayerPickProvider]): told who they're
    // waiting on, or, on a team with players, given the next step
    // (PLAYER-3, spec 6.3).
    final pick = isTeam && !isAdmin && mine.isEmpty
        ? ref.watch(myPlayerPickProvider(group.id))
        : const PlayerPick();
    final waiting = pick.stage == PlayerPickStage.waiting;
    final pointToWho = pick.unlinked && activePlayers > 0 && !event.isCanceled;
    // A team with no players takes no answers yet: its admins are told how
    // to start (PLAYER-6). Others, and everyone on an archived team, see no
    // section, unless their claim waits (spec 6.3).
    final noPlayers = isTeam && activePlayers == 0;
    if (noPlayers && !waiting && (!isAdmin || group.isArchived)) {
      return const SizedBox.shrink();
    }
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
    // Nothing would sit under the heading, like for an admin who answers
    // for nobody (spec 6.3): no section, and Who's going comes first.
    final bare =
        mine.isEmpty &&
        !addPlayers &&
        !waiting &&
        !pointToWho &&
        !event.isCanceled &&
        event.rsvpDeadline == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!bare)
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
                  // Add players goes back here, by the event's name (#14).
                  onPressed: () => context.push(
                    '/g/${group.id.value}/players/add',
                    extra: BackLabel(event.title),
                  ),
                  child: Text(l10n.rsvpAddPlayersAction),
                ),
              ],
            ),
          )
        else if (waiting)
          padded(Text(playerPickWaitingText(l10n, pick), style: muted))
        // A coach, or someone who said they're here for no player: the
        // rule, and a quiet way to say otherwise.
        else if (pointToWho && pick.stage == PlayerPickStage.adult)
          padded(
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.sm,
              children: [
                Text(l10n.rsvpPlayersOnly, style: muted),
                TextButton(
                  onPressed: () => openPlayerPick(context, group.id),
                  child: Text(l10n.whoAreYouHereFor),
                ),
              ],
            ),
          )
        // Anyone else not linked yet: the next step, as a real button
        // (owner's go 2026-11-16).
        else if (pointToWho)
          padded(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.playerPickToAnswer, style: muted),
                const SizedBox(height: Space.sm),
                FilledButton(
                  onPressed: () => openPlayerPick(context, group.id),
                  child: Text(l10n.pickMyPlayer),
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
        // Canceled events take no answers (SCHED-7). Each player I answer
        // for has their own row, with no all-players shortcut (PLAYER-11).
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
          // With no section, the details' last hairline is the line above,
          // as this one is after a section: RSVP for a player's 48 px row
          // centers the heading 9 lower, about a section's 14 (SPEC §7.3),
          // and without it the heading is 14 down.
          if (!bare) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: c.divider),
          ],
          Padding(
            padding: EdgeInsets.only(top: bare && !canSet ? 14 : 6),
            // Side by side while both fit, the button at the right; with
            // large text or a small phone the button goes under the
            // heading, rather than squeezing both onto two lines each (#74).
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      // On an event that's over, what people said, not who
                      // is going (#35).
                      event.endedBefore(DateTime.now())
                          ? l10n.eventWhoSaidGoing
                          : l10n.eventWhosGoing,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 25,
                        height: 30 / 25,
                      ),
                    ),
                  ),
                  if (canSet)
                    TextButton.icon(
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
                ],
              ),
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
                    // Boot Camp Mix (#85): the answer's own color, in
                    // an ink outline.
                    color: switch (s) {
                      RsvpStatus.going => c.mint.face,
                      RsvpStatus.maybe => c.lemon.face,
                      RsvpStatus.notGoing => CampPalette.cantGo,
                      null =>
                        c.roles.palette.text == c.ink
                            ? CampPalette.titleFill
                            : c.roles.palette.text,
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
/// note ("Leaving at halftime") on the event's page (SCHED-5). Everywhere
/// they show (the event's page, the chat's event card, the schedule list,
/// and Your schedule) tapping the chosen answer again clears it, back to
/// "No reply", followed by "Answer cleared · Undo", so a double tap that
/// clears an answer is never silent (#44).
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
    void pick(RsvpStatus s) {
      Haptics.selection();
      unawaited(_answer(context, ref, s, answer?.note ?? ''));
    }

    final onChanged = enabled ? pick : null;
    // One rule everywhere (#44): a tap on the chosen answer clears it, and
    // the snack bar's Undo puts back the answer and its note.
    final onCleared = enabled
        ? () => unawaited(
            clearRsvpWithFeedback(
              context,
              ref,
              event,
              participant,
              previous: answer,
            ),
          )
        : null;
    if (compact) {
      return _CardRsvpRow(
        label: label,
        semanticName: participant.shownName,
        // Nothing left to do once it can't be answered: no coral dot (#53).
        unanswered: current == null && enabled,
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
          onChanged: onChanged,
          onCleared: onCleared,
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
        // Add a note under the answer. There's no separate Clear link:
        // tapping the chosen answer again clears it, as everywhere (#44).
        if (!compact && enabled && current != null)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => unawaited(_editNote(context, ref, current)),
                icon: const Icon(AppIcons.edit, size: 18),
                label: Text(
                  answer?.note.isNotEmpty ?? false
                      ? l10n.eventEditNote
                      : l10n.eventAddNote,
                ),
              ),
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

/// Clears [participant]'s answer (SCHED-5) and says so: "Answer cleared"
/// with Undo, which writes [previous] (its answer and note) back (#44), or
/// why it was refused or failed.
///
/// The repository, the uid, the messenger, and the words are taken before
/// anything is awaited: once the answer is gone its buttons may rebuild or
/// leave (an event card scrolled away, say), and Undo still has to work.
Future<void> clearRsvpWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Event event,
  Participant participant, {
  Rsvp? previous,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(rsvpRepositoryProvider);
  final uid = ref.read(authUserProvider).value?.uid;
  Haptics.selection();
  try {
    await repo.clearRsvp(event, participant);
  } on AppFailure catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            e is PermissionDenied
                ? l10n.eventRsvpRefused
                : l10n.eventRsvpFailed,
          ),
        ),
      );
    return;
  }
  // Nothing to put back: no Undo, only the word that it's cleared.
  final undo = previous == null || uid == null
      ? null
      : SnackBarAction(
          label: l10n.eventAnswerClearedUndo,
          onPressed: () => unawaited(
            _restoreRsvp(
              repo,
              messenger,
              l10n,
              event,
              RsvpAnswer(
                participant: participant,
                status: previous.status,
                note: previous.note,
              ),
              UserId(uid),
            ),
          ),
        );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.eventAnswerCleared),
        action: undo,
        // Long enough to notice a slip and reach Undo, then it goes on its
        // own like any other snack bar, rather than waiting to be closed.
        duration: const Duration(seconds: 6),
        persist: false,
      ),
    );
}

/// Undo for a cleared answer (#44): writes it back, and says so if the
/// rules refuse (the deadline passed in between) or it fails.
Future<void> _restoreRsvp(
  RsvpRepository repo,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Event event,
  RsvpAnswer answer,
  UserId by,
) async {
  Haptics.selection();
  try {
    await repo.setRsvp(event, answer, by: by);
  } on AppFailure catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            e is PermissionDenied
                ? l10n.eventRsvpRefused
                : l10n.eventRsvpFailed,
          ),
        ),
      );
  }
}

/// One count on the event screen (SPEC §7.3; #85): the number in big stencil in
/// its answer's color, and its label in small capitals under it.
class _Count extends StatelessWidget {
  const new({required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedText(
            '$count',
            fill: color,
            stroke: 5,
            style: const TextStyle(
              fontFamily: AppFonts.stencil,
              fontWeight: FontWeight.w900,
              fontSize: 44,
              height: 42 / 44,
              letterSpacing: 44 * 0.03,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: TextStyle(
              fontFamily: AppFonts.stencil,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              height: 16 / 13,
              letterSpacing: 13 * 0.08,
              color: c.textOnPage,
            ),
          ),
        ],
      ),
    );
  }
}

/// The people by answer (SPEC §7.3; Boot Camp Mix, #85): an ink label for
/// each answer in its color with its dot ("GOING · 10"), then a row per
/// person, their dog tag hanging from the ball chain that rules off the
/// row.
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
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: _GroupLabel(
                // "No reply", as the count above it says.
                text:
                    '${s == null ? l10n.rsvpNoReply : statusLabel(l10n, s)}'
                    ' · ${list.length}',
                color: switch (s) {
                  null =>
                    c.roles.palette.text == c.ink
                        ? CampPalette.titleFill
                        : c.roles.palette.text,
                  RsvpStatus.notGoing => CampPalette.cantGo,
                  final s => statusAccent(context, s).face,
                },
              ),
            ),
            for (final (i, (p, r)) in list.indexed)
              _AttendeeRow(
                participant: p,
                rsvp: r,
                color: colorOf(p),
                answeredBy: _answeredBy(l10n, p, r),
                onTap: onTap?.call(p),
                index: i,
              ),
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
    this.index = 0,
  });

  /// Down its group, so the tags swing one way, then the other.
  final int index;

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
    final p = c.roles.palette;
    return FocusRingInk(
      onTap: onTap,
      child: CustomPaint(
        // The ball chain along the row's top, the tag hanging from it.
        painter: _BallChainPainter(color: p.ballChain),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 2.5, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DogTag.hanging(
                // Their initials, not the number's "#".
                name: name,
                colorKey: participant.id,
                color: color,
                turn: index.isEven ? -4 : 3,
                // Someone not coming, or not sure yet, hangs a plain tag.
                fill: s == RsvpStatus.going ? null : p.unansweredTag,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
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
                                style: body(
                                  17,
                                  FontWeight.w700,
                                  c.textMutedOnPage,
                                ),
                              ),
                          ],
                        ),
                        style: body(17, FontWeight.w700, c.textOnPage),
                      ),
                      if (note.isNotEmpty)
                        Text(
                          '"$note"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: body(15, FontWeight.w700, c.textOnPage),
                        ),
                      if (answeredBy case final by?)
                        Text(
                          by,
                          style: body(14, FontWeight.w700, c.textMutedOnPage),
                        ),
                    ],
                  ),
                ),
              ),
              if (s != null) ...[
                const SizedBox(width: 12),
                // The answer as a badge in its color, with its icon.
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: switch (s) {
                      RsvpStatus.notGoing => CampPalette.cantGo,
                      final s => statusAccent(context, s).face,
                    },
                    shape: BoxShape.circle,
                    border: Border.all(color: c.ink, width: 2.5),
                  ),
                  child: Icon(
                    statusIcon(s),
                    size: 15,
                    weight: 700,
                    color: c.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An answer's label over its people (#85): its name and count in stencil
/// in [color] on an ink block, with a dot in [color], turned -1.2°.
class _GroupLabel extends StatelessWidget {
  const new({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Semantics(
      container: true,
      header: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Transform.rotate(
          angle: -1.2 * 3.141592653589793 / 180,
          child: Container(
            color: c.ink,
            padding: const EdgeInsets.fromLTRB(9, 2, 10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    text.toUpperCase(),
                    semanticsLabel: text,
                    style: TextStyle(
                      fontFamily: AppFonts.stencil,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 21 / 15,
                      letterSpacing: 15 * 0.08,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ball chain the dog tags hang from (#85): 1.4 px beads every 7 px
/// along the top of a players row.
class _BallChainPainter extends CustomPainter {
  new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 5.5; x < size.width; x += 7) {
      canvas.drawCircle(Offset(x, 6.5), 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(_BallChainPainter old) => old.color != color;
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

  /// The room between a card's buttons, as [RsvpChoice] leaves it.
  static const double _pillGap = 9;

  @override
  Widget build(BuildContext context) {
    final text = label;
    if (text == null) return choice;
    final c = GumdropColors.of(context);
    // Boot Camp Mix (#85): "NOAH?" in stencil, mustard on the dark schemes'
    // answer row and ink on Light's pale one.
    final style = GumdropStyle.of(context).label(
      TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 15,
        height: 1.2,
        color: c.brightness == Brightness.dark
            ? c.roles.palette.mustard
            : c.textPrimary,
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
            child: Text('$text?', style: style, maxLines: 1),
          ),
          if (unanswered)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 9,
                height: 9,
                // Your own color: yours to answer, not a warning (#12), in
                // an ink ring so it shows on any panel (#85).
                decoration: BoxDecoration(
                  color: c.you.face,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.ink, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: '$text?', style: style),
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
