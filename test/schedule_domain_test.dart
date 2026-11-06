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
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
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
    test('a "This and following" preview starts on the series date and '
        "keeps a count series' total, as the server saves it (SCHED-6)", () {
      // Tue and Thu, 10 events, Oct 20 skipped: Oct 13, 15, 22, 27, 29,
      // Nov 3, 5, 10, 12, 17.
      const old = Recurrence(
        freq: RepeatFreq.weekly,
        startDate: '2026-10-13',
        byWeekday: [2, 4],
        count: 10,
        skipDates: ['2026-10-20'],
      );
      expect(datesBefore(old, '2026-10-27'), 3);
      // The Oct 27 event was moved to Wed Oct 28 with "This event".
      final draft = EventDraft(
        timeZone: 'America/Chicago',
        title: 'Practice',
        date: DateTime.utc(2026, 10, 28),
        repeat: RepeatRule.fromRecurrence(old),
        seriesFrom: '2026-10-27',
        countBefore: datesBefore(old, '2026-10-27'),
      );
      // Sent: the whole series' count, from the series date.
      expect(draft.recurrence?.startDate, '2026-10-27');
      expect(draft.recurrence?.count, 10);
      // Shown: the 7 the server keeps from there on.
      expect(draft.savedRecurrence?.count, 7);
      expect(draft.seriesDates?.dates, [
        '2026-10-27',
        '2026-10-29',
        '2026-11-03',
        '2026-11-05',
        '2026-11-10',
        '2026-11-12',
        '2026-11-17',
      ]);
      expect(draft.problemAt(DateTime.utc(2026, 10, 2)), isNull);
      // At least one, even when the count is lowered below what's past.
      final fewer = draft.copyWith(repeat: draft.repeat!.copyWith(count: 2));
      expect(fewer.seriesDates?.dates, ['2026-10-27']);
      // A rule that ends on a date is left as it is.
      final until = draft.copyWith(
        repeat: draft.repeat!.copyWith(
          endsOnDate: true,
          untilDate: '2026-11-05',
        ),
      );
      expect(until.seriesDates?.dates.length, 4);
    });

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
      // The automatic title stays automatic: a new opponent retitles it.
      expect(copy.title, '');
      expect(copy.effectiveTitle, 'vs. Eagles');
      expect(copy.copyWith(opponent: 'Hawks').effectiveTitle, 'vs. Hawks');
      // The deadline (Sun 7:00 PM, two days before) waits for a date...
      expect(copy.deadline, isNull);
      // ...and keeps its place before the new one, across the DST change.
      final dated = copy.copyWith(date: DateTime.utc(2026, 11, 10));
      expect(dated.deadline, DateTime.utc(2026, 11, 9, 1));
      expect(dated.problemAt(DateTime.utc(2026, 11)), isNull);
      // Picking or clearing a deadline replaces it.
      expect(
        dated
            .copyWith(deadlineDaysBefore: null, deadlineMinutes: null)
            .deadline,
        isNull,
      );
      final edit = EventDraft.fromEvent(e);
      expect(edit.date, DateTime.utc(2026, 10, 13));
      expect(edit.deadline, DateTime.utc(2026, 10, 12));
      expect(edit.effectiveTitle, 'vs. Eagles');
      // A title typed by hand stays as typed.
      final named = EventDraft.fromEvent(
        e.copyWith(title: 'Homecoming'),
        duplicate: true,
      );
      expect(named.copyWith(opponent: 'Hawks').effectiveTitle, 'Homecoming');
    });
  });

  group('text', () {
    final l10n = AppLocalizationsEn();

    test('event counts: players only on a team, everyone in a group '
        '(PLAYER-6)', () {
      final e = Event(
        id: const EventId('e'),
        groupId: const GroupId('g'),
        type: EventType.practice,
        title: 'Practice',
        startAt: DateTime.utc(2026, 10, 13, 23),
        endAt: DateTime.utc(2026, 10, 14),
        timeZone: 'America/Chicago',
        createdBy: 'a',
        rsvpCounts: const RsvpCounts(going: 12, maybe: 1),
        staffCounts: const RsvpCounts(going: 2, notGoing: 1),
      );
      // Old member answers on a team don't count.
      expect(eventCountsText(l10n, e, isTeam: true, total: 15), '12/15 going');
      // A team with no players has no count.
      expect(eventCountsText(l10n, e, isTeam: true, total: 0), isNull);
      // A group counts everyone together.
      expect(eventCountsText(l10n, e, isTeam: false, total: 20), '14/20 going');
      expect(goingOf(e, isTeam: true), 12);
      expect(goingOf(e, isTeam: false), 14);
      expect(
        const RsvpCounts(going: 1) + const RsvpCounts(maybe: 2, notGoing: 3),
        const RsvpCounts(going: 1, maybe: 2, notGoing: 3),
      );
    });

    test("cards say who hasn't answered (6.2)", () {
      const luke = Participant(
        type: ParticipantType.player,
        id: 'p1',
        name: 'Luke Dunphy',
      );
      const mine = Participant(
        type: ParticipantType.player,
        id: 'p2',
        name: 'Ann Lee',
        isMe: true,
      );
      expect(unansweredText(l10n, const []), isNull);
      expect(unansweredText(l10n, const [luke]), "Luke hasn't answered");
      expect(unansweredText(l10n, const [mine]), "You haven't answered");
      expect(unansweredText(l10n, const [luke, mine]), "2 haven't answered");
      expect(cardRsvpLabel(l10n, luke), 'Luke');
      expect(cardRsvpLabel(l10n, mine), 'You');
    });

    test('answer rows say whose they are (PLAYER-6)', () {
      const me = Participant(
        type: ParticipantType.member,
        id: 'u',
        name: 'Jared',
      );
      const emma = Participant(
        type: ParticipantType.player,
        id: 'p1',
        name: 'Emma R',
        label: 'Emma #7',
      );
      const self = Participant(
        type: ParticipantType.player,
        id: 'p2',
        name: 'Jared F',
        label: 'Jared #12',
        isMe: true,
      );
      expect(rsvpRowLabel(l10n, me, 1), isNull);
      expect(rsvpRowLabel(l10n, me, 2), 'You');
      // A player by their first name, my own player as You.
      expect(rsvpRowLabel(l10n, emma, 1), 'Emma');
      expect(rsvpRowLabel(l10n, self, 1), 'You');
      expect(answerLabel(l10n, me, [me]), isNull);
      expect(answerLabel(l10n, self, [self]), 'You');
      expect(answerLabel(l10n, emma, [self, emma]), 'Emma');
      // The question over my buttons on the event screen.
      expect(rsvpHeading(l10n, [me]), 'Are you going?');
      expect(rsvpHeading(l10n, [self]), 'Are you going?');
      expect(rsvpHeading(l10n, [emma]), 'Is Emma going?');
      expect(rsvpHeading(l10n, [self, emma]), 'Are your players going?');
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
    test('everyone on an event: the active players on a team, everyone in '
        'a group (SCHED-4, PLAYER-6)', () {
      Membership m(String uid, {MemberRole role = MemberRole.member}) =>
          Membership(
            groupId: const GroupId('g'),
            uid: UserId(uid),
            role: role,
            displayName: uid,
          );
      const players = [
        Player(id: PlayerId('p1'), groupId: GroupId('g'), displayName: 'Emma'),
        Player(
          id: PlayerId('p2'),
          groupId: GroupId('g'),
          displayName: 'Noah',
          status: PlayerStatus.pending,
        ),
      ];
      final roster = [
        m('coach', role: MemberRole.admin).copyWith(coach: true),
        m('maria'),
        m('sam'),
      ];
      // On a team, players only; pending players can't be answered for
      // (PLAYER-4), and coaches and other adults have no answer.
      final team = eventParticipants(roster, players, isTeam: true);
      expect(team.main.map((p) => p.id), ['p1']);
      expect(team.staff, isEmpty);
      // A team with no players yet has nobody to answer for.
      final empty = eventParticipants(roster, const [], isTeam: true);
      expect(empty.main, isEmpty);
      expect(empty.staff, isEmpty);
      // In a group, everyone answers for themselves.
      final group = eventParticipants(roster, const [], isTeam: false);
      expect(group.main, isEmpty);
      expect(group.staff.map((p) => p.id), ['coach', 'maria', 'sam']);
      expect(group.staff.every((p) => !p.isPlayer), isTrue);
    });

    const group = Group(
      id: GroupId('a'),
      name: 'Thunder',
      sport: Sport.soccer,
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

    test('a super admin makes events on a team they are not on (§3)', () {
      expect(canCreateEvents(group, null), isFalse);
      expect(canCreateEvents(group, null, superAdmin: true), isTrue);
      expect(
        canCreateEvents(
          group.copyWith(archivedAt: DateTime(2026)),
          null,
          superAdmin: true,
        ),
        isFalse,
      );
    });

    test('a reminder in chat: whoever manages the event, while it is on and '
        'not over (SCHED-8)', () {
      final now = DateTime.utc(2026, 10, 20, 12);
      final event = Event(
        id: const EventId('e1'),
        groupId: const GroupId('a'),
        type: EventType.practice,
        title: 'Practice',
        startAt: DateTime.utc(2026, 10, 20, 17),
        endAt: DateTime.utc(2026, 10, 20, 18),
        timeZone: 'America/New_York',
        createdBy: 'sam',
      );
      bool can(Event e, Membership? me, {bool superAdmin = false}) =>
          canRepost(e, group, me, superAdmin: superAdmin, now: now);
      expect(can(event, member('lee', role: MemberRole.admin)), isTrue);
      expect(can(event, member('sam')), isTrue);
      expect(can(event, member('kim')), isFalse);
      expect(can(event, null), isFalse);
      expect(
        can(
          event.copyWith(canceledAt: now),
          member('lee', role: MemberRole.admin),
        ),
        isFalse,
      );
      expect(
        canRepost(
          event,
          group,
          member('sam'),
          now: DateTime.utc(2026, 10, 20, 19),
        ),
        isFalse,
      );
    });

    test('members manage their own events, even once members may no longer '
        'make them (§3 "own only")', () {
      final event = Event(
        id: const EventId('e1'),
        groupId: const GroupId('a'),
        type: EventType.practice,
        title: 'Practice',
        startAt: DateTime.utc(2026, 10, 20, 17),
        endAt: DateTime.utc(2026, 10, 20, 18),
        timeZone: 'America/New_York',
        createdBy: 'sam',
      );
      // The team doesn't let members make events (any more).
      expect(group.settings.membersCanCreateEvents, isFalse);
      expect(canManageEvent(event, group, member('sam')), isTrue);
      expect(canManageEvent(event, group, member('kim')), isFalse);
      expect(
        canManageEvent(event, group, member('lee', role: MemberRole.admin)),
        isTrue,
      );
      expect(canManageEvent(event, group, null, superAdmin: true), isTrue);
      expect(canManageEvent(event, group, null), isFalse);
      expect(
        canManageEvent(
          event,
          group.copyWith(archivedAt: DateTime(2026)),
          member('sam'),
        ),
        isFalse,
      );
    });

    test('linked members answer for their players first; coaches and '
        'unlinked members also for themselves, after them (PLAYER-6)', () {
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
        Player(
          id: PlayerId('p3'),
          groupId: GroupId('a'),
          displayName: 'Jared F',
          jerseyNumber: '12',
        ),
        Player(
          id: PlayerId('p4'),
          groupId: GroupId('a'),
          displayName: 'Ava R',
          status: PlayerStatus.pending,
        ),
      ];
      const links = [
        GuardianLink(
          playerId: PlayerId('p1'),
          groupId: GroupId('a'),
          uid: UserId('maria'),
        ),
        GuardianLink(
          playerId: PlayerId('p3'),
          groupId: GroupId('a'),
          uid: UserId('jared'),
          relation: PlayerRelation.self,
        ),
        GuardianLink(
          playerId: PlayerId('p2'),
          groupId: GroupId('a'),
          uid: UserId('jared'),
        ),
        GuardianLink(
          playerId: PlayerId('p4'),
          groupId: GroupId('a'),
          uid: UserId('maria'),
        ),
      ];
      // A guardian answers only for their (active) players.
      final parent = participantsFor(
        me: member('maria'),
        isTeam: true,
        players: players,
        links: links,
      );
      expect(parent.map((p) => p.shownName), ['Emma #7']);
      expect(parent.single.isMe, isFalse);
      expect(parent.single.firstName, 'Emma');
      // A coach, admin, or owner guardian too: no answer of their own.
      for (final me in [
        member('maria').copyWith(coach: true),
        member('maria', role: MemberRole.admin),
        member('maria', role: MemberRole.owner),
      ]) {
        final mine = participantsFor(
          me: me,
          isTeam: true,
          players: players,
          links: links,
        );
        expect(mine.map((p) => p.type), [ParticipantType.player]);
      }
      // A member who is a player answers on their own player's row, first,
      // then for the players they're here for.
      final player = participantsFor(
        me: member('jared', role: MemberRole.owner),
        isTeam: true,
        players: players,
        links: links,
      );
      expect(player.map((p) => p.id), ['p3', 'p2']);
      expect(player.first.isMe, isTrue);
      expect(player.last.isMe, isFalse);
      // A member linked to nobody has nobody to answer for on a team...
      expect(
        participantsFor(me: member('sam'), isTeam: true, players: players),
        isEmpty,
      );
      // ...and in a group answers for themselves.
      final self = participantsFor(me: member('sam'), isTeam: false);
      expect(self.single.id, 'sam');
      expect(self.single.isPlayer, isFalse);
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
