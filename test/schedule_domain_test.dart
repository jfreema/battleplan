// The schedule's pure rules (SPEC SCHED-1, SCHED-3, SCHED-9, SCHED-10):
// series expansion against the server's vectors, time zones, the game
// title, counts, and the .ics file.
import 'dart:convert';
import 'dart:io';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/calendar.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('series expansion matches the server (shared vectors)', () {
    // Written by the backend next to its own tests; both sides must produce
    // `expected` from the same rule.
    final file = File('functions/test/unit/fixtures/series_vectors.json');
    final vectors =
        (jsonDecode(file.readAsStringSync()) as Map)['vectors'] as List;
    int minutes(String? hhmm) => hhmm == null
        ? 0
        : int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3));

    for (final v in vectors.cast<Map<String, dynamic>>()) {
      test(v['name'] as String, () {
        final r = v['recurrence'] as Map<String, dynamic>;
        final t = v['times'] as Map<String, dynamic>;
        final rule = Recurrence(
          freq: RepeatFreq.tryParse(r['freq'] as String)!,
          startDate: r['startDate'] as String,
          interval: r['interval'] as int,
          byWeekday: (r['byWeekday'] as List).cast<int>(),
          untilDate: r['untilDate'] as String?,
          count: r['count'] as int?,
          skipDates: (r['skipDates'] as List).cast<String>(),
        );
        final expected = (v['expected'] as List).cast<Map<String, dynamic>>();
        final dates = expandRecurrence(rule).dates;
        expect(dates, [for (final e in expected) e['date']]);

        final draft = EventDraft(
          timeZone: t['timeZone'] as String,
          allDay: t['allDay'] as bool,
          startMinutes: minutes(t['startTime'] as String?),
          endMinutes: minutes(t['endTime'] as String?),
        );
        for (final e in expected) {
          final day = parseDateKey(e['date'] as String);
          expect(
            draft.startOn(day).toIso8601String(),
            DateTime.parse(e['startAt'] as String).toIso8601String(),
            reason: 'start on ${e['date']}',
          );
          expect(
            draft.endOn(day).toIso8601String(),
            DateTime.parse(e['endAt'] as String).toIso8601String(),
            reason: 'end on ${e['date']}',
          );
        }
      });
    }

    test('skip dates that fall on the rule are listed apart', () {
      final out = expandRecurrence(
        const Recurrence(
          freq: RepeatFreq.weekly,
          startDate: '2026-10-13',
          byWeekday: [2, 4],
          untilDate: '2026-10-22',
          skipDates: ['2026-10-15', '2026-10-16'],
        ),
      );
      expect(out.dates, ['2026-10-13', '2026-10-20', '2026-10-22']);
      expect(out.skipped, ['2026-10-15']);
    });

    test('a rule needs days, an end, and an interval of 1 to 8', () {
      const ok = Recurrence(
        freq: RepeatFreq.weekly,
        startDate: '2026-10-13',
        byWeekday: [2],
        count: 4,
      );
      expect(ok.isValid, isTrue);
      expect(ok.copyWith(byWeekday: []).isValid, isFalse);
      expect(ok.copyWith(count: null).isValid, isFalse);
      expect(ok.copyWith(untilDate: '2026-12-01').isValid, isFalse);
      expect(ok.copyWith(interval: 9).isValid, isFalse);
      expect(
        ok.copyWith(count: null, untilDate: '2026-10-01').isValid,
        isFalse,
      );
    });
  });

  group('time zones (SCHED-9)', () {
    test('wall-clock time in a zone becomes the right instant', () {
      // 6 PM in Chicago: CDT (UTC-5) in October, CST (UTC-6) in November.
      expect(
        ZonedTime.instantOf(
          'America/Chicago',
          DateTime.utc(2026, 10, 13),
          18 * 60,
        ),
        DateTime.utc(2026, 10, 13, 23),
      );
      expect(
        ZonedTime.instantOf(
          'America/Chicago',
          DateTime.utc(2026, 11, 3),
          18 * 60,
        ),
        DateTime.utc(2026, 11, 4),
      );
      final wall = ZonedTime.wallClock(
        'America/New_York',
        DateTime.utc(2026, 10, 13, 23),
      );
      expect((wall.hour, wall.minute), (19, 0));
      expect(
        ZonedTime.abbreviation('America/Chicago', DateTime.utc(2026, 10, 13)),
        'CDT',
      );
    });

    test('"6:00 PM CDT · 7:00 PM your time" only when the zones differ', () {
      final l10n = AppLocalizationsEn();
      final e = Event(
        id: const EventId('e'),
        groupId: const GroupId('a'),
        type: EventType.practice,
        title: 'Practice',
        startAt: DateTime.utc(2026, 10, 13, 23),
        endAt: DateTime.utc(2026, 10, 14, 0, 30),
        timeZone: 'America/Chicago',
        createdBy: 'coach',
      );
      expect(
        otherZoneLine(l10n, e, 'America/New_York'),
        '6:00 PM CDT · 7:00 PM your time',
      );
      expect(otherZoneLine(l10n, e, 'America/Chicago'), isNull);
      expect(
        timeRange(l10n, e, 'America/Chicago', withDay: true),
        'Tue, Oct 13 · 6:00 PM – 7:30 PM',
      );
    });

    test('all-day events keep their dates in any zone', () {
      final l10n = AppLocalizationsEn();
      final e = Event(
        id: const EventId('e'),
        groupId: const GroupId('a'),
        type: EventType.other,
        title: 'Camp',
        allDay: true,
        startDate: '2026-07-06',
        endDate: '2026-07-08',
        startAt: DateTime.utc(2026, 7, 6, 5),
        endAt: DateTime.utc(2026, 7, 9, 5),
        timeZone: 'America/Chicago',
        createdBy: 'coach',
      );
      expect(
        timeRange(l10n, e, 'Asia/Tokyo', withDay: true),
        'Mon, Jul 6 – Wed, Jul 8 · All day',
      );
      expect(otherZoneLine(l10n, e, 'Asia/Tokyo'), isNull);
    });
  });

  group('the event form (SCHED-3)', () {
    test('a game left untitled is "vs. Eagles" or "@ Eagles"', () {
      expect(autoGameTitle(' Eagles ', null), 'vs. Eagles');
      expect(autoGameTitle('Eagles', HomeAway.home), 'vs. Eagles');
      expect(autoGameTitle('Eagles', HomeAway.away), '@ Eagles');
      expect(autoGameTitle(' ', HomeAway.away), '');
      const game = EventDraft(
        timeZone: 'America/Chicago',
        type: EventType.game,
        opponent: 'Eagles',
        homeAway: HomeAway.away,
      );
      expect(game.effectiveTitle, '@ Eagles');
      expect(game.copyWith(title: 'Final').effectiveTitle, 'Final');
      expect(game.copyWith(type: EventType.practice).effectiveTitle, isEmpty);
    });

    test('times: end at or before the start is the next day; all day is '
        'midnight to midnight', () {
      final d = EventDraft(
        timeZone: 'America/Chicago',
        date: DateTime.utc(2026, 10, 30),
        startMinutes: 22 * 60,
        endMinutes: 60,
      );
      expect(d.startAt, DateTime.utc(2026, 10, 31, 3));
      expect(d.endAt, DateTime.utc(2026, 10, 31, 6));
      final allDay = d.copyWith(allDay: true, endDate: DateTime.utc(2026, 11));
      expect(allDay.startAt, DateTime.utc(2026, 10, 30, 5));
      // Clocks fall back on Nov 1, so the next midnight is UTC-6.
      expect(allDay.endAt, DateTime.utc(2026, 11, 2, 6));
    });

    test('what keeps it from saving', () {
      final now = DateTime.utc(2026, 10, 12);
      final ok = EventDraft(
        timeZone: 'America/Chicago',
        title: 'Practice',
        date: DateTime.utc(2026, 10, 13),
      );
      expect(ok.problemAt(now), isNull);
      expect(ok.copyWith(title: ' ').problemAt(now), DraftProblem.title);
      expect(ok.copyWith(date: null).problemAt(now), DraftProblem.date);
      expect(
        ok.copyWith(rsvpDeadline: DateTime.utc(2026, 10, 14)).problemAt(now),
        DraftProblem.deadline,
      );
      expect(
        ok.copyWith(repeat: const RepeatRule()).problemAt(now),
        DraftProblem.repeat,
      );
      expect(
        ok
            .copyWith(
              repeat: const RepeatRule(byWeekday: [2], untilDate: '2026-11-03'),
            )
            .problemAt(now),
        isNull,
      );
    });

    test('Duplicate copies everything but the date (SCHED-3)', () {
      final e = Event(
        id: const EventId('e'),
        groupId: const GroupId('a'),
        type: EventType.game,
        title: 'vs. Eagles',
        opponent: 'Eagles',
        homeAway: HomeAway.home,
        arriveMinutesBefore: 30,
        startAt: DateTime.utc(2026, 10, 13, 23),
        endAt: DateTime.utc(2026, 10, 14, 0, 30),
        timeZone: 'America/Chicago',
        createdBy: 'coach',
        reminderOffsets: const [60],
        rsvpDeadline: DateTime.utc(2026, 10, 12),
        seriesId: 's1',
        canceledAt: DateTime.utc(2026, 10, 2),
      );
      final copy = EventDraft.fromEvent(e, duplicate: true);
      expect(copy.date, isNull);
      expect(copy.startMinutes, 18 * 60);
      expect(copy.endMinutes, 19 * 60 + 30);
      expect(copy.opponent, 'Eagles');
      expect(copy.arriveMinutesBefore, 30);
      expect(copy.reminderOffsets, [60]);
      expect(copy.rsvpDeadline, isNull);
      expect(copy.repeat, isNull);
      final edit = EventDraft.fromEvent(e);
      expect(edit.date, DateTime.utc(2026, 10, 13));
    });
  });

  group('text', () {
    final l10n = AppLocalizationsEn();

    test('counts: "12 going · 3 maybe · 2 no" (SCHED-1)', () {
      const c = RsvpCounts(going: 12, maybe: 3, notGoing: 2);
      expect(countsText(l10n, c), '12 going · 3 maybe · 2 no');
      expect(countsText(l10n, c, allowMaybe: false), '12 going · 2 no');
      expect(countsText(l10n, const RsvpCounts(going: 4)), '4 going');
      expect(countsText(l10n, const RsvpCounts()), 'No answers yet');
    });

    test('the series summary and repeat line (SCHED-3, SCHED-4)', () {
      const rule = Recurrence(
        freq: RepeatFreq.weekly,
        startDate: '2026-10-13',
        byWeekday: [4, 2],
        untilDate: '2026-12-17',
      );
      final dates = expandRecurrence(rule).dates;
      expect(
        seriesSummary(l10n, EventType.practice, rule, dates),
        '20 practices · Tue and Thu · Oct 13 – Dec 17',
      );
      expect(
        repeatsLine(l10n, rule),
        'Repeats weekly on Tue and Thu until Dec 17',
      );
      expect(
        repeatsLine(
          l10n,
          rule.copyWith(byWeekday: [1, 3, 5], untilDate: null, count: 10),
        ),
        'Repeats weekly on Mon, Wed, and Fri, 10 times',
      );
      expect(
        repeatsLine(
          l10n,
          const Recurrence(
            freq: RepeatFreq.daily,
            startDate: '2026-07-06',
            interval: 2,
            untilDate: '2026-07-20',
          ),
        ),
        'Repeats every 2 days until Jul 20',
      );
      expect(
        [for (final m in reminderOffsetsMinutes) reminderLabel(l10n, m)],
        ['15 min', '1 h', '2 h', '1 day', '2 days', '1 week'],
      );
    });
  });

  group('who may do what (Q12, PLAYER-6, Q14)', () {
    const group = Group(
      id: GroupId('a'),
      name: 'Thunder',
      sport: Sport.soccer,
      teamType: TeamType.youth,
      memberCount: 3,
    );
    Membership member(String uid, {MemberRole role = MemberRole.member}) =>
        Membership(
          groupId: const GroupId('a'),
          uid: UserId(uid),
          role: role,
          displayName: uid,
        );

    test('only admins make events unless the team allows members', () {
      expect(canCreateEvents(group, member('sam')), isFalse);
      expect(
        canCreateEvents(group, member('lee', role: MemberRole.admin)),
        isTrue,
      );
      final open = group.copyWith(
        settings: const GroupSettings(membersCanCreateEvents: true),
      );
      expect(canCreateEvents(open, member('sam')), isTrue);
      expect(
        canCreateEvents(
          open.copyWith(archivedAt: DateTime(2026)),
          member('sam'),
        ),
        isFalse,
      );
    });

    test('guardians answer for their players; admins also for themselves', () {
      const players = [
        Player(
          id: PlayerId('p1'),
          groupId: GroupId('a'),
          displayName: 'Emma R',
          jerseyNumber: '7',
        ),
        Player(
          id: PlayerId('p2'),
          groupId: GroupId('a'),
          displayName: 'Liam R',
        ),
      ];
      const links = [
        GuardianLink(
          playerId: PlayerId('p1'),
          groupId: GroupId('a'),
          uid: UserId('maria'),
        ),
      ];
      final parent = participantsFor(
        group: group,
        me: member('maria'),
        players: players,
        links: links,
      );
      expect(parent.map((p) => p.shownName), ['Emma #7']);
      final coach = participantsFor(
        group: group,
        me: member('maria', role: MemberRole.admin),
        players: players,
        links: links,
      );
      expect(coach.map((p) => p.type), [
        ParticipantType.member,
        ParticipantType.player,
      ]);
      final adult = participantsFor(
        group: group.copyWith(teamType: TeamType.adult),
        me: member('sam'),
      );
      expect(adult.single.id, 'sam');
    });
  });

  test('the .ics file for the web download (SCHED-10)', () {
    final ics = buildIcs(
      CalendarEntry(
        id: 'e1',
        title: 'Practice, Field 2',
        start: DateTime.utc(2026, 10, 13, 23),
        end: DateTime.utc(2026, 10, 14, 0, 30),
        timeZone: 'America/Chicago',
        location: 'Riverside Park',
      ),
      now: DateTime.utc(2026, 10, 12, 9),
    );
    expect(ics, contains('DTSTART:20261013T230000Z\r\n'));
    expect(ics, contains('DTEND:20261014T003000Z\r\n'));
    expect(ics, contains(r'SUMMARY:Practice\, Field 2'));
    expect(ics, contains('UID:e1@getbattleplan.app'));
    final allDay = buildIcs(
      CalendarEntry(
        id: 'e2',
        title: 'Camp',
        start: DateTime.utc(2026, 7, 6, 5),
        end: DateTime.utc(2026, 7, 9, 5),
        timeZone: 'America/Chicago',
        allDay: true,
        startDate: DateTime.utc(2026, 7, 6),
        endDate: DateTime.utc(2026, 7, 9),
      ),
      now: DateTime.utc(2026, 7, 2),
    );
    expect(allDay, contains('DTSTART;VALUE=DATE:20260706'));
    expect(allDay, contains('DTEND;VALUE=DATE:20260709'));
  });
}
