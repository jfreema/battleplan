import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_repository.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/contrast.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// Events whose live lists fail [fails] times, before anything (or, with
/// [afterData], after their first answer), then answer; a calendar month
/// that fails; one event's page that fails; and Load more that fails once.
class _FlakyEvents extends FakeEventRepository {
  new(super.events);

  int fails = 0;
  bool afterData = false;
  int rangeFails = 0;
  int eventFails = 0;
  int moreFails = 0;
  bool paged = false;
  int subscriptions = 0;

  Stream<T> _flaky<T>(Stream<T> real) {
    if (fails <= 0) return real;
    fails--;
    if (!afterData) return Stream.error(StateError('offline'));
    return (() async* {
      yield await real.first;
      throw StateError('offline');
    })();
  }

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) {
    // The chat's Next up (#43) reads the next five on its own: not the
    // list these tests make fail.
    if (limit == 5) return super.watchUpcoming(groupId, from, limit: limit);
    subscriptions++;
    final real = super.watchUpcoming(groupId, from, limit: limit);
    return _flaky(
      paged
          ? real.map((p) => (events: p.events, next: const PageCursor('more')))
          : real,
    );
  }

  @override
  Future<EventPage> loadMore(
    GroupId groupId,
    PageCursor cursor, {
    required bool past,
    int limit = 50,
  }) async {
    if (moreFails > 0) {
      moreFails--;
      throw StateError('offline');
    }
    return (events: const <Event>[], next: null);
  }

  @override
  Stream<List<Event>> watchRange(
    GroupId groupId,
    DateTime from,
    DateTime until,
  ) {
    if (rangeFails > 0) {
      rangeFails--;
      return Stream.error(StateError('offline'));
    }
    return super.watchRange(groupId, from, until);
  }

  @override
  Stream<Event?> watchEvent(EventId id) {
    if (eventFails > 0) {
      eventFails--;
      return Stream.error(StateError('Unreadable event ${id.value}'));
    }
    return super.watchEvent(id);
  }
}

/// Documents whose list fails [fails] times (after its first answer with
/// [afterData]), and one document's page that fails [docFails] times.
class _FlakyDocuments extends FakeDocumentRepository {
  new(super.docs);

  int fails = 0;
  bool afterData = false;
  int docFails = 0;

  @override
  Stream<DocumentPage> watchFirstPage(
    GroupId groupId,
    DocumentSort sort, {
    int limit = Limits.queryLimitMax,
  }) {
    final real = super.watchFirstPage(groupId, sort, limit: limit);
    if (fails <= 0) return real;
    fails--;
    if (!afterData) return Stream.error(StateError('offline'));
    return (() async* {
      yield await real.first;
      throw StateError('offline');
    })();
  }

  @override
  Stream<Document?> watchDocument(DocumentId id) {
    if (docFails > 0) {
      docFails--;
      return Stream.error(StateError('Unreadable document ${id.value}'));
    }
    return super.watchDocument(id);
  }
}

/// #40: one record the app can't read never blanks a list, and a list that
/// stops says so: "Couldn't load" with Try again while nothing shows, or
/// what it has kept under "Couldn't refresh." (SPEC SCHED-1, DOC-1, §7.5).
void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const zone = 'America/Chicago';
  Event practice(String id, int days) {
    final now = ZonedTime.wallClock(zone, DateTime.now());
    final start = ZonedTime.instantOf(
      zone,
      DateTime.utc(now.year, now.month, now.day).add(Duration(days: days)),
      18 * 60,
    );
    return Event(
      id: EventId(id),
      groupId: const GroupId('a'),
      type: EventType.practice,
      title: 'Practice $id',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      timeZone: zone,
      createdBy: 'coach',
    );
  }

  Future<void> open(
    WidgetTester tester,
    String path, {
    FakeEventRepository? events,
    FakeDocumentRepository? documents,
    TeamScheme scheme = TeamScheme.dark,
    Size size = const Size(400, 1000),
  }) async {
    final eventRepo = events ?? FakeEventRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      prefs: FakeLocalPrefs()
        ..defaultSchemeValue = scheme
        ..pushPrePromptShown = true,
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [
        testMembership(
          'a',
          'coach',
          role: MemberRole.owner,
        ).copyWith(colorScheme: scheme),
      ],
      eventRepo: eventRepo,
      rsvpRepo: FakeRsvpRepository(eventRepo),
      documentRepo: documents,
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  Future<void> tryAgain(WidgetTester tester) async {
    await tester.tap(find.text('Try again').first);
    await tester.pumpAndSettle();
  }

  group('LoadError and the notice', () {
    Future<void> pumpOne(WidgetTester tester, Widget child) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          ),
        );

    testWidgets('the full form: the sentence and a coral Try again, heard '
        'once', (tester) async {
      final handle = tester.ensureSemantics();
      var tries = 0;
      await pumpOne(tester, LoadError(onRetry: () => tries++));
      expect(
        find.text("Couldn't load this. Check your connection and try again."),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
      expect(tries, 1);
      expect(
        tester.getSemantics(find.byType(LoadError)),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('the inline form: one line and a quiet link', (tester) async {
      var tries = 0;
      await pumpOne(tester, LoadError(inline: true, onRetry: () => tries++));
      expect(find.text("Couldn't load this."), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Try again'));
      expect(tries, 1);
    });

    testWidgets('the notice: "Couldn\'t refresh." and Try again', (
      tester,
    ) async {
      var tries = 0;
      await pumpOne(tester, RefreshFailedNotice(onRetry: () => tries++));
      expect(find.text("Couldn't refresh."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(tries, 1);
    });
  });

  group('the Schedule', () {
    testWidgets('failed before anything showed says so; Try again brings the '
        'events', (tester) async {
      final events = _FlakyEvents([practice('1', 1), practice('2', 2)])
        ..fails = 1;
      await open(tester, '/g/a/schedule', events: events);
      expect(find.byType(LoadError), findsOneWidget);
      expect(find.text('Practice 1'), findsNothing);
      // Never the empty state's next step.
      expect(find.text('Add your first practice or game'), findsNothing);
      await tryAgain(tester);
      expect(find.byType(LoadError), findsNothing);
      expect(find.text('Practice 1'), findsOneWidget);
      expect(events.subscriptions, greaterThanOrEqualTo(2));
    });

    testWidgets('failed after showing events keeps them, under "Couldn\'t '
        'refresh."', (tester) async {
      final events = _FlakyEvents([practice('1', 1)])
        ..fails = 1
        ..afterData = true;
      await open(tester, '/g/a/schedule', events: events);
      expect(find.text('Practice 1'), findsOneWidget);
      expect(find.text("Couldn't refresh."), findsOneWidget);
      await tryAgain(tester);
      expect(find.text("Couldn't refresh."), findsNothing);
      expect(find.text('Practice 1'), findsOneWidget);
    });

    testWidgets('Load more that fails says so, with Try again', (tester) async {
      final events = _FlakyEvents([practice('1', 1)])
        ..paged = true
        ..moreFails = 1;
      await open(tester, '/g/a/schedule', events: events);
      await tester.ensureVisible(find.text('Load more'));
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load more."), findsOneWidget);
      await tryAgain(tester);
      expect(find.text("Couldn't load more."), findsNothing);
    });

    testWidgets('a month that fails says so, not an empty calendar', (
      tester,
    ) async {
      final events = _FlakyEvents([practice('1', 1)])..rangeFails = 1;
      await open(tester, '/g/a/schedule', events: events);
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(LoadError), findsOneWidget);
      await tryAgain(tester);
      expect(find.byType(LoadError), findsNothing);
    });

    testWidgets("an event's page that can't be read says so, not \"not "
        'found"', (tester) async {
      final events = _FlakyEvents([practice('1', 1)])..eventFails = 1;
      await open(tester, '/g/a/schedule/e/1', events: events);
      expect(find.byType(LoadError), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
      await tryAgain(tester);
      expect(find.text('Practice 1'), findsWidgets);
    });
  });

  testWidgets('Your schedule on Teams fails quietly, one line with Try '
      'again', (tester) async {
    final events = _FlakyEvents([practice('1', 1)])..fails = 1;
    await open(tester, '/teams', events: events);
    expect(find.text("Couldn't load this."), findsOneWidget);
    // Not the full form, which would take over Teams.
    expect(find.byType(FilledButton), findsNothing);
    await tryAgain(tester);
    expect(find.text("Couldn't load this."), findsNothing);
    expect(find.text('Practice 1'), findsOneWidget);
  });

  group('Documents', () {
    final roster = Document(
      id: const DocumentId('d1'),
      groupId: const GroupId('a'),
      kind: DocumentKind.link,
      name: 'Roster',
      url: 'https://example.com',
      uploadedBy: 'coach',
      uploaderName: 'Coach',
      createdAt: DateTime(2030),
    );

    testWidgets('failed before anything showed says so; Try again brings '
        'them', (tester) async {
      final docs = _FlakyDocuments([roster])..fails = 1;
      await open(tester, '/g/a/documents', documents: docs);
      expect(find.byType(LoadError), findsOneWidget);
      await tryAgain(tester);
      expect(find.text('Roster'), findsOneWidget);
    });

    testWidgets('failed after showing them keeps them, under "Couldn\'t '
        'refresh."', (tester) async {
      final docs = _FlakyDocuments([roster])
        ..fails = 1
        ..afterData = true;
      await open(tester, '/g/a/documents', documents: docs);
      expect(find.text('Roster'), findsOneWidget);
      expect(find.text("Couldn't refresh."), findsOneWidget);
      await tryAgain(tester);
      expect(find.text("Couldn't refresh."), findsNothing);
    });

    testWidgets("a document's page that can't be read says so", (tester) async {
      final docs = _FlakyDocuments([roster])..docFails = 1;
      await open(tester, '/g/a/documents/d/d1', documents: docs);
      expect(find.byType(LoadError), findsOneWidget);
      await tryAgain(tester);
      expect(find.byType(LoadError), findsNothing);
    });
  });

  testWidgets('reads well: the notice heard once, 48 px targets, contrast '
      'in every scheme, and 200% text', (tester) async {
    for (final scheme in bootCampSchemes) {
      final events = _FlakyEvents([practice('1', 1)])
        ..fails = 1
        ..afterData = true;
      await open(tester, '/g/a/schedule', events: events, scheme: scheme);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(RefreshFailedNotice)),
        isSemantics(isLiveRegion: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      final failing = _FlakyEvents([practice('1', 1)])..fails = 1;
      await open(tester, '/g/a/schedule', events: failing, scheme: scheme);
      final again = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      again.dispose();
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final events = _FlakyEvents([practice('1', 1)])
      ..fails = 1
      ..afterData = true;
    await open(
      tester,
      '/g/a/schedule',
      events: events,
      size: const Size(320, 1000),
    );
    expect(tester.takeException(), isNull);
  });
}
