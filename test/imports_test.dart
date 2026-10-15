// Importing a team's events from another app (SPEC §6.15, IMPORT-1 to
// IMPORT-5): GameChanger's schedule, by its calendar link or a calendar
// file, previewed before anything is added.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/imports/data/functions_import_repository.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
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

  Future<FakeImportRepository> openImport(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
    FakeImportRepository? repo,
    FakeFileChooser? files,
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
        expect(find.text('GameChanger'), findsOneWidget);
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
        "That isn't a calendar. In GameChanger, use Copy Calendar Link.",
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
      final repo = FunctionsImportRepository(functions);
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
        FunctionsImportRepository(functions).importEvents(
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
}
