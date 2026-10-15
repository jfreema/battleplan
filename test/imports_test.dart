// Importing a team from another app (SPEC §6.15, IMPORT-1 to IMPORT-9):
// GameChanger's and TeamReach's schedules by their calendar links, and a
// GroupMe group's messages, files, and events from its data export, each
// previewed before anything is added.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/imports/application/groupme_import.dart';
import 'package:battleplan/features/imports/data/functions_import_repository.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/imports/domain/groupme_export.dart';
import 'package:battleplan/features/imports/domain/roster_file.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fake_functions.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final team = {'a': testGroup('a', 'Thunder')};

  /// Import, as [role], with [source] chosen.
  Future<FakeImportRepository> openImport(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
    FakeImportRepository? repo,
    FakeFileChooser? files,
    String source = 'GameChanger',
  }) async {
    final imports = repo ?? FakeImportRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: team,
      memberships: [testMembership('a', 'coach', role: role)],
      importRepo: imports,
      fileChooser: files,
      size: const Size(500, 2400),
    );
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push('/g/a/import'),
    );
    await tester.pumpAndSettle();
    if (find.text(source).evaluate().isNotEmpty) {
      await tester.tap(find.text(source));
      await tester.pumpAndSettle();
    }
    return imports;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  group('the team menu (SPEC §6.15)', () {
    for (final (role, shown) in [
      (MemberRole.owner, true),
      (MemberRole.admin, true),
      (MemberRole.member, false),
    ]) {
      testWidgets('offers Import to ${role.name}s: $shown', (tester) async {
        await pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: team,
          memberships: [testMembership('a', 'coach', role: role)],
        );
        await tester.tap(find.byTooltip('Team menu'));
        await tester.pumpAndSettle();
        expect(find.text('Import'), shown ? findsOneWidget : findsNothing);
        if (!shown) return;
        await tester.tap(find.text('Import'));
        await tester.pumpAndSettle();
        for (final app in [
          'GroupMe',
          'TeamSnap',
          'TeamReach',
          'GameChanger',
          'Google Calendar',
        ]) {
          expect(find.text(app), findsOneWidget);
        }
      });
    }
  });

  group('importing GameChanger events (IMPORT-1 to IMPORT-5)', () {
    testWidgets('only events can be chosen; chat, documents, and RSVPs stay '
        'behind', (tester) async {
      await openImport(tester);
      final events = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Events'),
      );
      expect(events.value, isTrue);
      for (final label in ['Messages', 'Documents']) {
        final box = tester.widget<CheckboxListTile>(
          find.widgetWithText(CheckboxListTile, label),
        );
        expect(box.value, isFalse, reason: label);
        expect(box.onChanged, isNull, reason: label);
      }
      expect(
        find.text("GameChanger doesn't export team chat."),
        findsOneWidget,
      );
      expect(
        find.text("RSVPs and attendance aren't imported."),
        findsOneWidget,
      );
      // With nothing chosen there's nothing to preview.
      await tapText(tester, 'Events');
      final preview = find.widgetWithText(FilledButton, 'Preview');
      expect(tester.widget<FilledButton>(preview).onPressed, isNull);
    });

    testWidgets('a link is needed first', (tester) async {
      final repo = await openImport(tester);
      await tapText(tester, 'Preview');
      expect(
        find.text('Paste the calendar link, or choose a calendar file.'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    });

    testWidgets('preview, then import, then on to the schedule', (
      tester,
    ) async {
      final repo = await openImport(
        tester,
        repo: FakeImportRepository(
          imported: const EventImportResult(
            added: 3,
            alreadyImported: 1,
            past: 2,
            skippedCount: 1,
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Calendar link'),
        ' webcal://api.example.com/team.ics ',
      );
      await tapText(tester, 'Include past events');
      await tapText(tester, 'Include past events');
      await tapText(tester, 'Preview');
      expect(repo.calls, [
        'preview link webcal://api.example.com/team.ics past=false',
      ]);
      // What's new, what's already here, and what's left out, and why.
      expect(find.text('3 events to add'), findsOneWidget);
      expect(
        find.text('1 already imported · 2 past events left out · 1 skipped'),
        findsOneWidget,
      );
      expect(find.text('vs. Eagles'), findsOneWidget);
      expect(
        find.textContaining('Riverside Park, 100 River Rd'),
        findsOneWidget,
      );
      // Shown in the event's own zone: 10 AM in Chicago.
      expect(find.textContaining('10:00'), findsOneWidget);
      expect(find.text('Season kickoff BBQ'), findsOneWidget);
      expect(find.text('Canceled in GameChanger'), findsOneWidget);
      // Changing anything takes the preview away.
      await tapText(tester, 'Include past events');
      expect(find.text('3 events to add'), findsNothing);
      await tapText(tester, 'Preview');
      expect(
        repo.calls.last,
        'preview link webcal://api.example.com/team.ics past=true',
      );

      await tapText(tester, 'Import 3 events');
      expect(
        repo.calls.last,
        'import link webcal://api.example.com/team.ics past=true',
      );
      expect(find.text('3 events added to the schedule.'), findsOneWidget);
      await tapText(tester, 'Open the schedule');
      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('a calendar file works instead of the link', (tester) async {
      const ics = 'BEGIN:VCALENDAR\nEND:VCALENDAR\n';
      final files = FakeFileChooser(
        next: (
          name: 'thunder.ics',
          size: ics.length,
          readBytes: () async => Uint8List.fromList(utf8.encode(ics)),
        ),
      );
      final repo = await openImport(tester, files: files);
      await tapText(tester, 'Use a calendar file (.ics) instead');
      expect(files.extensions, ['ics']);
      expect(find.text('thunder.ics'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Calendar link'), findsNothing);
      await tapText(tester, 'Preview');
      expect(repo.calls, ['preview file ${ics.length} chars past=false']);
      // Removing the file brings the link back.
      await tester.tap(find.byTooltip('Remove file'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Calendar link'), findsOneWidget);
    });

    testWidgets('a file over 1 MB is refused before sending', (tester) async {
      final files = FakeFileChooser(
        next: (
          name: 'huge.ics',
          size: 2000000,
          readBytes: () async => Uint8List(0),
        ),
      );
      final repo = await openImport(tester, files: files);
      await tapText(tester, 'Use a calendar file (.ics) instead');
      expect(
        find.text('That file is over 1 MB, too large for a calendar.'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    });

    testWidgets('nothing new says so, with no Import button', (tester) async {
      await openImport(
        tester,
        repo: FakeImportRepository(
          preview: const EventImportResult(
            added: 0,
            alreadyImported: 12,
            past: 0,
            skippedCount: 0,
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Calendar link'),
        'https://example.com/a.ics',
      );
      await tapText(tester, 'Preview');
      expect(find.text('Nothing new to import.'), findsOneWidget);
      expect(find.text('12 already imported'), findsOneWidget);
      expect(find.textContaining('Import '), findsNothing);
    });

    for (final (failure, said) in [
      (
        const InvalidInput('bad-link'),
        "That isn't a calendar link. Copy it again from GameChanger.",
      ),
      (
        const InvalidInput('not-a-calendar'),
        "That isn't a calendar. Copy the calendar link from GameChanger again.",
      ),
      (
        const InvalidInput('calendar-unreachable'),
        "Couldn't open that link. Check it and try again.",
      ),
      (
        const StorageFull('storage-full'),
        "Your team's storage is full. Free up space in Media, then import.",
      ),
      (
        const PermissionDenied('team-archived'),
        'This team is archived and read-only.',
      ),
      (const Offline(), "You're offline. Check your connection and try again."),
    ]) {
      testWidgets('a refusal says why: ${failure.message}', (tester) async {
        await openImport(tester, repo: FakeImportRepository(failure: failure));
        await tester.enterText(
          find.widgetWithText(TextField, 'Calendar link'),
          'https://example.com/a.ics',
        );
        await tapText(tester, 'Preview');
        expect(find.text(said), findsOneWidget);
      });
    }

    testWidgets("members can't open it", (tester) async {
      final repo = await openImport(tester, role: MemberRole.member);
      expect(find.text("You can't do that on this team."), findsOneWidget);
      expect(find.text('GameChanger'), findsNothing);
      expect(repo.calls, isEmpty);
    });
  });

  group('the importEvents callable (data)', () {
    test('sends the link or the file, and reads the answer', () async {
      final functions = FakeFunctions({
        'importEvents': (_) => {
          'added': 2,
          'alreadyImported': 1,
          'past': 3,
          'skippedCount': 1,
          'skipped': [
            {'title': 'Parents meeting', 'startMs': 1, 'reason': 'repeat'},
          ],
          'firstMs': 1000,
          'lastMs': 2000,
          'sample': [
            {
              'title': 'vs. Eagles',
              'type': 'game',
              'allDay': false,
              'startMs': 1000,
              'startDate': null,
              'timeZone': 'America/Chicago',
              'place': 'Riverside Park',
            },
          ],
        },
      });
      final repo = FunctionsImportRepository(functions, MockFirebaseStorage());
      final r = await repo.importEvents(
        const GroupId('a'),
        source: ImportSource.gamechanger,
        includePast: false,
        dryRun: true,
        url: 'webcal://x',
      );
      expect(functions.lastData('importEvents'), {
        'groupId': 'a',
        'source': 'gamechanger',
        'url': 'webcal://x',
        'includePast': false,
        'dryRun': true,
      });
      expect(r.added, 2);
      expect(r.alreadyImported, 1);
      expect(r.past, 3);
      expect(r.skipped.single.reason, ImportSkipReason.repeat);
      expect(r.first, DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true));
      expect(r.sample.single.type, EventType.game);
      expect(r.sample.single.place, 'Riverside Park');

      await repo.importEvents(
        const GroupId('a'),
        source: ImportSource.gamechanger,
        includePast: true,
        dryRun: false,
        ics: 'BEGIN:VCALENDAR',
      );
      expect(functions.lastData('importEvents'), {
        'groupId': 'a',
        'source': 'gamechanger',
        'ics': 'BEGIN:VCALENDAR',
        'includePast': true,
        'dryRun': false,
      });
    });

    test("the web's status after a refusal doesn't hide the reason", () async {
      final functions = FakeFunctions()
        ..web = true
        ..fail('importEvents', 'failed-precondition', 'not-a-calendar');
      await expectLater(
        FunctionsImportRepository(
          functions,
          MockFirebaseStorage(),
        ).importEvents(
          const GroupId('a'),
          source: ImportSource.gamechanger,
          includePast: false,
          dryRun: true,
          url: 'https://example.com/a.ics',
        ),
        throwsA(
          isA<InvalidInput>().having(
            (f) => f.message,
            'message',
            'not-a-calendar',
          ),
        ),
      );
      expect(serverMessage('too-many-pins [400]'), 'too-many-pins');
      expect(serverMessage('too-many-pins'), 'too-many-pins');
      expect(serverMessage(null), isNull);
    });

    test('refusals become the failures the screen explains', () {
      expect(failureOf('invalid-argument', 'bad-link'), isA<InvalidInput>());
      expect(
        failureOf('failed-precondition', 'not-a-calendar'),
        isA<InvalidInput>().having(
          (f) => f.message,
          'message',
          'not-a-calendar',
        ),
      );
      expect(
        failureOf('failed-precondition', 'storage-full'),
        isA<StorageFull>(),
      );
      expect(
        failureOf('failed-precondition', 'team-archived'),
        isA<PermissionDenied>(),
      );
      expect(failureOf('permission-denied', null), isA<PermissionDenied>());
      expect(failureOf('resource-exhausted', null), isA<RateLimited>());
      expect(failureOf('unavailable', null), isA<Offline>());
      expect(failureOf('internal', 'x'), isA<UnknownFailure>());
    });
  });

  group('TeamReach (IMPORT-8)', () {
    testWidgets('takes its calendar link, and says what stays behind', (
      tester,
    ) async {
      final repo = await openImport(tester, source: 'TeamReach');
      expect(find.text('Your TeamReach schedule link'), findsOneWidget);
      expect(
        find.text("TeamReach doesn't export team messages."),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Calendar link'),
        'https://teamreach.example/ical/abc.ics',
      );
      await tapText(tester, 'Preview');
      const link = 'https://teamreach.example/ical/abc.ics';
      expect(repo.calls, ['teamreach preview link $link past=false']);
      expect(find.text('Canceled in TeamReach'), findsOneWidget);
    });
  });

  group('TeamSnap (IMPORT-11)', () {
    final today = DateTime.utc(2026, 10, 15);

    test('reads a roster: players only, with numbers and birthdates', () {
      final csv = [
        '\uFEFF${[
          'First Name', 'Last Name', 'Jersey Number', 'Position', //
          'Non-Player', 'Birthdate', 'Email Address 1',
        ].join(',')}',
        'Emma,Ortiz,7,SS,No,03/09/2014,emma.parent@example.com',
        '"Liam ""LJ""",Brooks,23,,No,2014-11-30,',
        'Pat,Coach,,,Yes,,coach@example.com',
        'Noah,Kim,4,,,02/30/2014,',
        'Emma,Ortiz,7,SS,No,03/09/2014,',
        ',,,,,,',
        '"Mia, Jr.",Lee,12345,,No,March 3 2015,',
      ].join('\r\n');
      final r = readRosterCsv(csv, today: today);
      expect(
        [
          for (final p in r.players)
            '${p.name}|${p.jerseyNumber}|${p.dateOfBirth}',
        ],
        [
          'Emma Ortiz|7|2014-03-09',
          'Liam "LJ" Brooks|23|2014-11-30',
          // Not a real date: the player comes without one.
          'Noah Kim|4|null',
          // Five digits isn't a jersey number the roster takes.
          'Mia, Jr. Lee|null|2015-03-03',
        ],
      );
      expect(r.nonPlayers, 1);
      expect(r.datesUnreadable, 1);
    });

    test("reads TeamSnap's own columns and member types", () {
      // TeamSnap's team roster template, and its club export's Member Type
      // (P, C, M, V: player, coach, manager, volunteer).
      final team = readRosterCsv(
        [
          [
            'First Name', 'Last Name', 'Email Address 1', 'Gender', //
            'Birthday', 'Jersey Number', 'Position', 'Non-Player (Y/N)',
          ].join(','),
          'Emma,Ortiz,,F,03/09/2014,7,SS,N',
          'Pat,Coach,pat@example.com,,,,,Y',
        ].join('\n'),
        today: today,
      );
      expect(team.players.single.dateOfBirth, '2014-03-09');
      expect(team.nonPlayers, 1);
      final club = readRosterCsv(
        'first,last,Member Type,birthdate,Jersey Number\n'
        'Liam,Brooks,P,11/30/2014,23\n'
        'Jo,Diaz,M,,\n'
        'Ann,Lee,V,,\n',
        today: today,
      );
      expect(club.players.single.name, 'Liam Brooks');
      expect(club.nonPlayers, 2);
    });

    test("takes other rosters too, and refuses what isn't one", () {
      final r = readRosterCsv(
        'Name;#;DOB;Role\nSam Rivera;12;12/1/13;Player\nJo Diaz;;;Manager\n',
        today: today,
      );
      expect(r.players.single.name, 'Sam Rivera');
      expect(r.players.single.jerseyNumber, '12');
      expect(r.players.single.dateOfBirth, '2013-12-01');
      expect(r.nonPlayers, 1);
      expect(
        () => readRosterCsv('Date,Opponent\n10/1,Eagles\n', today: today),
        throwsA(isA<NotRosterFile>()),
      );
    });

    testWidgets('schedule, players, and files, each on its own; chat '
        'stays behind', (tester) async {
      const csv =
          'First Name,Last Name,Jersey Number,Non-Player,Birthdate\n'
          'Emma,Ortiz,7,No,03/09/2014\n'
          'Sam,Rivera,12,No,\n'
          'Pat,Coach,,Yes,\n';
      final pdf = Uint8List.fromList(List.filled(20, 1));
      final files =
          FakeFileChooser(
              next: (
                name: 'roster.csv',
                size: csv.length,
                readBytes: () async => Uint8List.fromList(utf8.encode(csv)),
              ),
            )
            ..nextMany = [
              (name: 'rules.pdf', size: pdf.length, readBytes: () async => pdf),
            ];
      final players = FakePlayerRepository([
        const Player(
          id: PlayerId('p1'),
          groupId: GroupId('a'),
          displayName: 'Sam Rivera',
          jerseyNumber: '12',
        ),
      ]);
      final repo = FakeImportRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: team,
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        importRepo: repo,
        fileChooser: files,
        playerRepo: players,
        size: const Size(500, 3000),
      );
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push('/g/a/import'),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'TeamSnap');
      final chat = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Chat'),
      );
      expect(chat.onChanged, isNull);
      expect(
        find.text("TeamSnap doesn't let teams export their chat."),
        findsOneWidget,
      );
      const link = 'webcal://ical.teamsnap.example/team.ics';
      await tester.enterText(
        find.widgetWithText(TextField, 'Calendar link'),
        link,
      );
      await tapText(tester, 'Choose the roster file (.csv)');
      expect(files.extensions, ['csv']);
      expect(find.text('2 players'), findsOneWidget);
      await tapText(tester, 'Choose the files');
      expect(find.text('rules.pdf'), findsOneWidget);

      await tapText(tester, 'Preview');
      expect(repo.calls, [
        'teamsnap preview link $link past=false',
        'check documents 1',
      ]);
      expect(find.text('1 player to add'), findsOneWidget);
      expect(find.text('1 is already on the roster.'), findsOneWidget);
      expect(
        find.text('1 coach or other non-player left out.'),
        findsOneWidget,
      );
      expect(find.text('1 document to add'), findsOneWidget);

      final run = find.widgetWithText(FilledButton, 'Import');
      await tester.ensureVisible(run);
      await tester.pumpAndSettle();
      await tester.tap(run);
      await tester.pumpAndSettle();
      expect(
        players.added.single.single,
        const NewPlayer(
          name: 'Emma Ortiz',
          jerseyNumber: '7',
          dateOfBirth: '2014-03-09',
        ),
      );
      expect(repo.uploads.keys.single, endsWith('/rules.pdf'));
      expect(find.text('3 events added to the schedule.'), findsOneWidget);
      expect(find.text('1 player added to the roster.'), findsOneWidget);
      expect(find.text('1 document added.'), findsOneWidget);
      expect(find.text('Open the roster'), findsOneWidget);
    });
  });

  group('Google Calendar (IMPORT-10)', () {
    testWidgets("takes a calendar's secret iCal address", (tester) async {
      final repo = await openImport(tester, source: 'Google Calendar');
      expect(find.text('Your Google Calendar schedule link'), findsOneWidget);
      expect(
        find.textContaining('Secret address in iCal format'),
        findsOneWidget,
      );
      expect(find.text('Google Calendar has no team chat.'), findsOneWidget);
      const link =
          'https://calendar.google.com/calendar/ical/x/private-y/basic.ics';
      await tester.enterText(
        find.widgetWithText(TextField, 'Calendar link'),
        link,
      );
      await tapText(tester, 'Preview');
      expect(repo.calls, ['google preview link $link past=false']);
      expect(find.text('Canceled in Google Calendar'), findsOneWidget);
    });
  });

  group("GroupMe's export (IMPORT-9)", () {
    test('is read: messages oldest first, photos and files from the '
        'gallery, events from the calendar, and what stays behind', () {
      final export = readGroupMeExport(groupMeZip());
      final g = export.groups.single;
      expect(g.name, 'Thunder Softball');
      expect(g.messages.map((m) => m.id), [
        '101',
        '102',
        '103',
        '104',
        '105',
        '107',
      ]);
      final byId = {for (final m in g.messages) m.id: m};
      expect(byId['102']!.text, 'Meet here\n📍 Riverside Park');
      expect(
        byId['103']!.photos.single.entry,
        '53526472/gallery/103_1200x900.aaaabbbb.jpeg',
      );
      expect(byId['103']!.photos.single.contentType, 'image/jpeg');
      expect(export.bytesOf(byId['103']!.photos.single.entry), hasLength(10));
      // A reply, and GroupMe's own emoji, which only its apps draw.
      expect(byId['104']!.replyToId, '101');
      expect(byId['104']!.text, 'Yes');
      expect(byId['104']!.authorName, 'Sam');
      final file = g.files.single;
      expect(
        [file.name, file.contentType, file.size, file.sharedByName],
        ['league rules.pdf', 'application/pdf', 20, 'Riley'],
      );
      final left = g.leftOut;
      expect(
        [
          left.systemMessages,
          left.videos,
          left.photosNotInExport,
          left.filesUnsupported,
        ],
        [1, 1, 1, 1],
      );
      expect(g.events.map((e) => e.sourceId), ['ev1', 'ev2', 'ev3']);
      final game = g.events.first;
      expect(game.title, 'Thunder vs. Eagles');
      expect(game.location, 'Riverside Park, 100 River Rd');
      expect(game.timeZone, 'America/Chicago');
      expect(game.start, DateTime.utc(2031, 5, 2, 23));
      expect(g.events[1].allDay, isTrue);
      expect(g.events[2].canceled, isTrue);
    });

    test("isn't anything else", () {
      expect(
        () => readGroupMeExport(Uint8List.fromList(utf8.encode('hello'))),
        throwsA(isA<NotGroupMeExport>()),
      );
      final photos = Archive()..addFile(ArchiveFile.string('a.jpg', 'x'));
      expect(
        () => readGroupMeExport(ZipEncoder().encodeBytes(photos)),
        throwsA(
          isA<NotGroupMeExport>().having(
            (e) => e.reason,
            'reason',
            'not-an-export',
          ),
        ),
      );
      final dmOnly = Archive()
        ..addFile(ArchiveFile.string('11+22/message.json', '[]'));
      expect(
        () => readGroupMeExport(ZipEncoder().encodeBytes(dmOnly)),
        throwsA(
          isA<NotGroupMeExport>().having(
            (e) => e.reason,
            'reason',
            'no-groups',
          ),
        ),
      );
    });

    test("gives each item the server's ID", () {
      const team = GroupId('teamA');
      expect(
        importedItemId(
          team,
          ImportSource.groupme,
          ImportItemKind.message,
          '154321',
        ),
        'imp-602ca240b0e48726ba5ed6d556f7',
      );
      expect(
        importedItemId(
          team,
          ImportSource.groupme,
          ImportItemKind.document,
          'f1',
        ),
        'imp-0ac814c2f6001d68b54bfe9b6bba',
      );
    });

    test('imports events, then files, then messages, each just once', () async {
      final export = readGroupMeExport(groupMeZip());
      final repo = FakeImportRepository();
      Future<GroupMeTotals> run() =>
          GroupMeImporter(repo, const GroupId('a'), export).run(
            export.groups.single,
            messages: true,
            photos: true,
            documents: true,
            events: true,
            includePast: false,
          );
      final totals = await run();
      expect(repo.calls, [
        'import groupme events 3 past=false',
        'check documents 1',
        'import documents 1',
        'check messages 6',
        'import messages 6',
      ]);
      expect(
        [totals.eventsAdded, totals.documentsAdded, totals.messagesAdded],
        [3, 1, 6],
      );
      // Each file in its item's own folder.
      final docId = importedItemId(
        const GroupId('a'),
        ImportSource.groupme,
        ImportItemKind.document,
        '107_0',
      );
      final photoFolder = importedItemId(
        const GroupId('a'),
        ImportSource.groupme,
        ImportItemKind.message,
        '103',
      );
      expect(repo.uploads, {
        'groups/a/documents/$docId/league rules.pdf': 20,
        'groups/a/messages/$photoFolder/0.jpg': 10,
      });
      expect(repo.messages['103']!.photos.single.width, 4);
      expect(repo.messages['104']!.replyToSourceId, '101');

      // Again: everything's there, and nothing goes up twice.
      repo.uploads.clear();
      final again = await run();
      expect(
        [again.messagesAdded, again.messagesAlready, again.documentsAlready],
        [0, 6, 1],
      );
      expect(repo.uploads, isEmpty);
    });

    test('keeps bringing messages when storage fills up', () async {
      final export = readGroupMeExport(groupMeZip());
      final repo = FakeImportRepository()..roomBytes = 15;
      final totals = await GroupMeImporter(repo, const GroupId('a'), export)
          .run(
            export.groups.single,
            messages: true,
            photos: true,
            documents: true,
            events: false,
            includePast: false,
          );
      expect(totals.storageFull, isTrue);
      expect([totals.documentsLeftOut, totals.photosLeftOut], [1, 1]);
      // The photo-only message has nothing left to show.
      expect(totals.messagesAdded, 5);
    });

    test('stops between batches, keeping what was added', () async {
      final group = GroupMeGroup(
        id: '1',
        name: 'Big group',
        messages: [
          for (var i = 0; i < 600; i++)
            GroupMeMessage(
              id: '$i',
              authorId: '9',
              authorName: 'Sam',
              text: 'Message $i',
              createdAt: DateTime.utc(2025).add(Duration(minutes: i)),
            ),
        ],
        files: const [],
        events: const [],
        leftOut: const GroupMeLeftOut(),
      );
      final repo = FakeImportRepository();
      final importer = GroupMeImporter(
        repo,
        const GroupId('a'),
        GroupMeExport(groups: [group], read: (_) => null),
      );
      final totals = await importer.run(
        group,
        messages: true,
        photos: true,
        documents: true,
        events: true,
        includePast: false,
        onProgress: (p) {
          if (p.done > 0) importer.cancel();
        },
      );
      expect(totals.canceled, isTrue);
      expect(totals.messagesAdded, groupMeMessageBatch);
    });

    testWidgets('choose the export, see what it holds, then import', (
      tester,
    ) async {
      final zip = groupMeZip();
      final files = FakeFileChooser(
        next: (
          name: 'groupme-export.zip',
          size: zip.length,
          readBytes: () async => zip,
        ),
      );
      final repo = await openImport(tester, source: 'GroupMe', files: files);
      expect(
        find.textContaining('web.groupme.com', findRichText: true),
        findsOneWidget,
      );
      await tapText(tester, 'Choose the export (.zip)');
      expect(files.extensions, ['zip']);
      expect(find.text('groupme-export.zip'), findsOneWidget);
      expect(find.textContaining('6 messages'), findsOneWidget);
      expect(find.text('1 photo, 10 B'), findsOneWidget);
      expect(find.text('1 file shared in the group'), findsOneWidget);
      expect(find.text("3 events from the group's calendar"), findsOneWidget);

      await tapText(tester, 'Preview');
      expect(repo.calls, ['preview groupme events 3 past=false']);
      expect(find.text('6 messages to add'), findsOneWidget);
      expect(find.text('1 document to add'), findsOneWidget);
      expect(find.text('league rules.pdf'), findsOneWidget);
      expect(find.text('· 1 video'), findsOneWidget);
      expect(find.text('3 events to add'), findsOneWidget);

      final run = find.widgetWithText(FilledButton, 'Import');
      await tester.ensureVisible(run);
      await tester.pumpAndSettle();
      await tester.tap(run);
      await tester.pumpAndSettle();
      expect(find.text('6 messages added to the chat.'), findsOneWidget);
      expect(find.text('1 document added.'), findsOneWidget);
      expect(find.text('3 events added to the schedule.'), findsOneWidget);
      await tapText(tester, 'Open the chat');
      expect(find.byTooltip('Team menu'), findsOneWidget);
    });

    testWidgets("says when a file isn't an export", (tester) async {
      final files = FakeFileChooser(
        next: (
          name: 'photos.zip',
          size: 5,
          readBytes: () async => Uint8List.fromList(utf8.encode('hello')),
        ),
      );
      await openImport(tester, source: 'GroupMe', files: files);
      await tapText(tester, 'Choose the export (.zip)');
      expect(
        find.text(
          "That isn't a GroupMe export. Choose the .zip file GroupMe made.",
        ),
        findsOneWidget,
      );
    });

    test(
      'the callables get the batches, and checks list what is there',
      () async {
        final functions = FakeFunctions({
          'importMessages': (_) => {
            'added': 1,
            'alreadyImported': 1,
            'photosMissing': 0,
            'existing': ['6'],
          },
          'importDocuments': (_) => {
            'added': 0,
            'alreadyImported': 0,
            'missing': 1,
          },
        });
        final repo = FunctionsImportRepository(
          functions,
          MockFirebaseStorage(),
        );
        final check = await repo.importMessages(
          const GroupId('a'),
          source: ImportSource.groupme,
          check: true,
          messages: [
            ChatImportMessage(
              sourceId: '7',
              authorSourceId: '22',
              authorName: 'Riley',
              text: 'Yes',
              createdAt: DateTime.utc(2025, 3, 3),
              replyToSourceId: '6',
              photos: const [
                ChatImportPhoto(
                  path: 'groups/a/messages/x/0.jpg',
                  width: 4,
                  height: 3,
                ),
              ],
            ),
          ],
        );
        expect(functions.lastData('importMessages'), {
          'groupId': 'a',
          'source': 'groupme',
          'messages': [
            {
              'sourceId': '7',
              'authorSourceId': '22',
              'authorName': 'Riley',
              'text': 'Yes',
              'createdAtMs': DateTime.utc(2025, 3, 3).millisecondsSinceEpoch,
              'replyToSourceId': '6',
              'photos': [
                {'path': 'groups/a/messages/x/0.jpg', 'width': 4, 'height': 3},
              ],
            },
          ],
          'dryRun': true,
        });
        expect(check.existing, {'6'});
        final docs = await repo.importDocuments(
          const GroupId('a'),
          source: ImportSource.groupme,
          documents: [
            ChatImportDocument(
              sourceId: 'f1',
              name: 'rules.pdf',
              path: 'groups/a/documents/d/rules.pdf',
              sharedByName: 'Riley',
              sharedAt: DateTime.utc(2025),
            ),
          ],
        );
        expect(docs.missing, 1);
        expect(
          (functions.lastData('importDocuments')! as Map)['dryRun'],
          isFalse,
        );
      },
    );
  });
}

/// A GroupMe export like a real one (a group's folder, its messages newest
/// first, a gallery, likes, and a direct message), with a calendar file.
Uint8List groupMeZip() {
  const t = 1700000000;
  Map<String, Object?> m(
    String id,
    int at,
    String name,
    String text, [
    List<Object?> attachments = const [],
    Map<String, Object?> extra = const {},
  ]) => {
    'id': id,
    'created_at': t + at,
    'sender_id': name == 'Sam' ? '11' : '22',
    'user_id': name == 'Sam' ? '11' : '22',
    'sender_type': 'user',
    'name': name,
    'text': text,
    'system': false,
    'favorited_by': <String>[],
    'attachments': attachments,
    ...extra,
  };
  final messages = [
    m('108', 800, 'GroupMe', 'Riley added Sam to the group.', const [], {
      'system': true,
      'sender_type': 'system',
      'sender_id': 'system',
    }),
    m('107', 700, 'Riley', 'Shared a document: https://s.groupme.com/x', [
      {'type': 'file', 'file_id': 'uuid-1'},
    ]),
    m('106', 600, 'Riley', '', [
      {'type': 'file', 'file_id': 'uuid-2'},
    ]),
    m(
      '105',
      500,
      'Sam',
      'Game film https://v.groupme.com/1/abc.1280x720r0.mp4',
      [
        {'type': 'video', 'url': 'https://v.groupme.com/1/abc.1280x720r0.mp4'},
      ],
    ),
    m('104', 400, 'Sam', 'Yes �', [
      {'type': 'reply', 'reply_id': '101', 'base_reply_id': '101'},
      {
        'type': 'emoji',
        'placeholder': '�',
        'charmap': [
          [1, 8],
        ],
      },
    ]),
    m('103', 300, 'Riley', '', [
      {'type': 'image', 'url': 'https://i.groupme.com/1200x900.jpeg.aaaabbbb'},
    ]),
    m('102', 200, 'Riley', 'Meet here', [
      {'type': 'location', 'name': 'Riverside Park', 'lat': '1', 'lng': '2'},
    ]),
    m('101', 100, 'Sam', 'Field 3?'),
    m('100', 50, 'Sam', 'Gone', const [], {'deleted_at': t + 60}),
    m('099', 0, 'Riley', '', [
      {'type': 'image', 'url': 'https://i.groupme.com/800x600.png.cccc'},
    ]),
  ];
  Map<String, Object?> event(
    String id,
    String name,
    String start,
    String end, {
    bool allDay = false,
    bool gone = false,
  }) => {
    'event_id': id,
    'conversation_id': '53526472',
    'name': name,
    'description': 'Bring water',
    'start_at': start,
    'end_at': end,
    'is_all_day': allDay,
    'timezone': 'America/Chicago',
    'location': {'name': 'Riverside Park', 'address': '100 River Rd'},
    'deleted_at': gone ? '2031-04-01T00:00:00Z' : null,
  };
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '53526472/conversation.json',
        jsonEncode({'id': '53526472', 'name': 'Thunder Softball'}),
      ),
    )
    ..addFile(ArchiveFile.string('53526472/message.json', jsonEncode(messages)))
    ..addFile(
      ArchiveFile.string(
        '53526472/likes/mine.json',
        jsonEncode({
          'meta': <String, Object?>{},
          'response': {'count': 0, 'messages': <Object?>[]},
        }),
      ),
    )
    ..addFile(
      ArchiveFile.bytes(
        '53526472/gallery/103_1200x900.aaaabbbb.jpeg',
        List.filled(10, 1),
      ),
    )
    ..addFile(
      ArchiveFile.bytes(
        '53526472/gallery/107_league rules.pdf',
        List.filled(20, 2),
      ),
    )
    ..addFile(
      ArchiveFile.bytes('53526472/gallery/106_playbook.zip', List.filled(5, 3)),
    )
    ..addFile(
      ArchiveFile.bytes(
        '53526472/gallery/105_abc.1280x720r0.mp4',
        List.filled(30, 4),
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '11+22/conversation.json',
        jsonEncode({'id': '11+22'}),
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '11+22/message.json',
        jsonEncode([m('900', 0, 'Sam', 'A direct message')]),
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'calendar.json',
        jsonEncode({
          'response': {
            'events': [
              event(
                'ev3',
                'Canceled practice',
                '2031-07-01T18:00:00-05:00',
                '2031-07-01T19:00:00-05:00',
                gone: true,
              ),
              event(
                'ev1',
                'Thunder vs. Eagles',
                '2031-05-02T18:00:00-05:00',
                '2031-05-02T20:00:00-05:00',
              ),
              event(
                'ev2',
                'Picnic',
                '2031-06-06T00:00:00-05:00',
                '2031-06-07T00:00:00-05:00',
                allDay: true,
              ),
            ],
          },
        }),
      ),
    );
  return ZipEncoder().encodeBytes(archive);
}
