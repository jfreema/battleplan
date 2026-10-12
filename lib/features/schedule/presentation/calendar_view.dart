import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The Calendar view (SCHED-1): a month grid with a dot for each event
/// (in its type's color), and the chosen day's events below it.
class CalendarView extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// The first of the month shown, and the day picked (date-only, UTC).
  DateTime? _month;
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final zone = ref.watch(viewerTimeZoneProvider).value;
    if (zone == null) return const SkeletonList();
    final now = ZonedTime.wallClock(zone, DateTime.now());
    final today = DateTime.utc(now.year, now.month, now.day);
    final month = _month ?? DateTime.utc(today.year, today.month);
    final selected = _selected ?? today;
    final options = ref.watch(scheduleViewProvider);
    final async = options.allTeams
        ? ref.watch(allTeamsMonthEventsProvider(month))
        : ref.watch(monthEventsProvider(widget.groupId, month));
    final events = [
      for (final e in async.value ?? const <Event>[])
        if (options.shows(e)) e,
    ];
    final byDay = <DateTime, List<Event>>{};
    for (final e in events) {
      // Multi-day all-day events show on each of their days.
      final first = dayOf(e, zone);
      final last = e.allDay && e.endDate != null
          ? parseDateKey(e.endDate!)
          : first;
      for (var d = first; !d.isAfter(last); d = addDays(d, 1)) {
        (byDay[d] ??= []).add(e);
      }
    }

    // Weeks start on the locale's first day (Sunday in the US).
    final firstWeekday = MaterialLocalizations.of(context)
        .firstDayOfWeekIndex; // 0 = Sunday
    final lead = (month.weekday % 7 - firstWeekday) % 7;
    final gridStart = addDays(month, -lead);
    final nextMonth = DateTime.utc(month.year, month.month + 1);
    final weeks = ((lead + daysBetween(month, nextMonth)) / 7).ceil();
    final dayEvents = byDay[selected] ?? const <Event>[];
    // "My RSVPs" for what the grid shows, from the earliest event in it.
    final window = calendarWindow(zone, month);
    final earliest = events.isEmpty ? null : events.first.startAt;
    final rsvpRange = (
      from: earliest != null && earliest.isBefore(window.from)
          ? earliest
          : window.from,
      until: window.until,
    );

    void go(int months) => setState(() {
      _month = DateTime.utc(month.year, month.month + months);
      _selected = _month;
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxxl * 2),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.calendarPreviousMonth,
                icon: const Icon(AppIcons.chevronLeft),
                onPressed: () => go(-1),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(l10n.localeName).format(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.calendarNextMonth,
                icon: const Icon(AppIcons.chevronRight),
                onPressed: () => go(1),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          DateFormat.E(l10n.localeName)
                              .format(addDays(gridStart, i))
                              .characters
                              .first,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (var w = 0; w < weeks; w++)
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _DayCell(
                          day: addDays(gridStart, w * 7 + i),
                          inMonth:
                              addDays(gridStart, w * 7 + i).month ==
                              month.month,
                          isToday: addDays(gridStart, w * 7 + i) == today,
                          isSelected: addDays(gridStart, w * 7 + i) == selected,
                          events:
                              byDay[addDays(gridStart, w * 7 + i)] ?? const [],
                          onTap: () => setState(
                            () => _selected = addDays(gridStart, w * 7 + i),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Divider(height: Space.xl),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Space.gutter(MediaQuery.sizeOf(context).width),
          ),
          child: Text(
            dayLabel(l10n, selected),
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (async.isLoading && !async.hasValue)
          const LinearProgressIndicator()
        else if (dayEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(
              l10n.scheduleEmptyDay,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final e in dayEvents)
            ScheduleEventRow(
              event: e,
              viewerZone: zone,
              showTeam: options.allTeams,
              rsvpRange: rsvpRange,
            ),
      ],
    );
  }
}

/// One day of the month grid: its number and up to three dots.
class _DayCell extends StatelessWidget {
  const new({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<Event> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${dayLabel(l10n, day)}, ${l10n.calendarEventCount(events.length)}',
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its semantics.
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.chip),
        onTap: onTap,
        child: Container(
          // At least 48 tall, taller with large text (SPEC §7.6).
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : null,
            border: isToday ? Border.all(color: scheme.primary) : null,
            borderRadius: BorderRadius.circular(Corners.chip),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: inMonth ? null : scheme.outline,
                  fontWeight: isToday ? FontWeight.w700 : null,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final e in events.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: e.isCanceled
                            ? scheme.outline
                            : typeColor(context, e.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
